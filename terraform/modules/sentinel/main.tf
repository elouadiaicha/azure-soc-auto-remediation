terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }
}

# 1. Création du Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "soc" {
  name                = var.workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# 2. Onboarding de Microsoft Sentinel sur le Workspace
resource "azurerm_sentinel_log_analytics_workspace_onboarding" "sentinel" {
  workspace_id = azurerm_log_analytics_workspace.soc.id
}

# 3. Collecte des AzureActivity logs de la Souscription vers Log Analytics
resource "azurerm_monitor_diagnostic_setting" "subscription_activity_logs" {
  name                       = "diag-azure-activity-to-sentinel"
  target_resource_id         = "/subscriptions/${var.subscription_id}"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.soc.id

  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Security"
  }
}

# 4. Règle d'Analyse Programmée Sentinel (Analytics Rule)
resource "azurerm_sentinel_alert_rule_scheduled" "nsg_ssh_alert" {
  name                       = "SOC-SSH-Ouvert-Internet"
  log_analytics_workspace_id = azurerm_sentinel_log_analytics_workspace_onboarding.sentinel.workspace_id
  display_name               = "SOC - SSH ouvert à Internet"
  severity                   = "High"
  enabled                    = true

  # Fréquence d'exécution : Toutes les 5 minutes sur la fenêtre des 15 dernières minutes
  query_frequency   = "PT5M"
  query_period      = "PT15M"
  trigger_operator  = "GreaterThan"
  trigger_threshold = 0

  query = <<QUERY
AzureActivity
| where TimeGenerated > ago(15m)
| where ActivityStatusValue =~ "Success"
| where OperationNameValue =~ "Microsoft.Network/networkSecurityGroups/securityRules/write"
| where _ResourceId has "${var.target_nsg_rule_name}"
| project
    TimeGenerated,
    Caller,
    CallerIpAddress,
    ResourceGroup,
    OperationNameValue,
    _ResourceId
QUERY

  #   # Génération automatique de l'Incident dans Sentinel
  #   incident_configuration {
  #     create_incident = true
  #     grouping {
  #       enabled = false
  #     }
  #   }

  # Mapping d'entités (permet à Sentinel de relier l'attaquant/utilisateur et l'IP dans l'investigation)
  entity_mapping {
    entity_type = "Account"
    field_mapping {
      identifier  = "Name"
      column_name = "Caller"
    }
  }

  entity_mapping {
    entity_type = "IP"
    field_mapping {
      identifier  = "Address"
      column_name = "CallerIpAddress"
    }
  }

  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.sentinel
  ]
}

# 1. Récupérer le Service Principal natif de Microsoft Sentinel
data "azuread_service_principal" "sentinel_sp" {
  display_name = "Azure Security Insights"
}

# 2. Accorder les permissions d'exécution de Playbook à Sentinel sur le RG
resource "azurerm_role_assignment" "sentinel_playbook_permissions" {
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
  role_definition_name = "Microsoft Sentinel Automation Contributor"
  principal_id         = data.azuread_service_principal.sentinel_sp.object_id
}

resource "time_sleep" "wait_rbac_propagation" {
  create_duration = "60s"

  depends_on = [
    azurerm_role_assignment.sentinel_playbook_permissions
  ]
}

# 2. Règle d'Automatisation Sentinel (Automation Rule)
# C'est la passerelle entre l'Incident Sentinel et la Logic App
resource "azurerm_sentinel_automation_rule" "remediate_ssh" {
  name                       = "c4d8e9a2-1b3f-4e5a-8c7d-9e0f1a2b3c4d"
  log_analytics_workspace_id = azurerm_sentinel_log_analytics_workspace_onboarding.sentinel.workspace_id
  display_name               = "Auto-Remédiation : Trigger Logic App"
  order                      = 1
  triggers_on                = "Incidents"
  triggers_when              = "Created"

  # Format JSON conforme à l'API Azure Sentinel
  condition_json = jsonencode([
    {
      conditionType = "Property"
      conditionProperties = {
        propertyName   = "IncidentRelatedAnalyticRuleIds"
        operator       = "Contains"
        propertyValues = [azurerm_sentinel_alert_rule_scheduled.nsg_ssh_alert.id]
      }
    }
  ])

  # Action : Exécuter le Playbook (Logic App)
  action_playbook {
    logic_app_id = var.logic_app_id
    order        = 1
  }

  depends_on = [
    azurerm_sentinel_alert_rule_scheduled.nsg_ssh_alert,
    time_sleep.wait_rbac_propagation
  ]
}

resource "azurerm_sentinel_automation_rule" "remediate_ssh_demo" {
  name                       = "d5e9f0b3-2c4a-5f6b-9d8e-0f1a2b3c4d5e"
  log_analytics_workspace_id = azurerm_sentinel_log_analytics_workspace_onboarding.sentinel.workspace_id
  display_name               = "DEMO - Trigger Logic App (sans filtre)"
  order                      = 2
  triggers_on                = "Incidents"
  triggers_when              = "Created"

  action_playbook {
    logic_app_id = var.logic_app_id
    order        = 1
  }
}
