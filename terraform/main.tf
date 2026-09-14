data "azurerm_resource_group" "soc" {
  name = var.resource_group_name
}

module "remediation" {
  source = "./modules/remediation"

  resource_group_name = var.resource_group_name
  location            = data.azurerm_resource_group.soc.location
  nsg_name            = var.nsg_name
  logic_app_name      = "logic-soc-remediation"
}
