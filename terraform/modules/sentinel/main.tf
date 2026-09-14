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
