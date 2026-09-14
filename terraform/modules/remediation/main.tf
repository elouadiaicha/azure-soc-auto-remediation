data "azurerm_network_security_group" "soc" {
  name                = var.nsg_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_logic_app_workflow" "remediation" {
  name                = var.logic_app_name
  location            = var.location
  resource_group_name = var.resource_group_name

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "logic_app_network_contributor" {
  scope                = data.azurerm_network_security_group.soc.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_logic_app_workflow.remediation.identity[0].principal_id
}
