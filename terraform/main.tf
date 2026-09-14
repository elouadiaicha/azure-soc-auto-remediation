data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

module "infrastructure" {
  source = "./modules/infrastructure"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  vnet_name           = var.vnet_name
  nsg_name            = var.nsg_name
}

module "remediation" {
  source = "./modules/remediation"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  nsg_name            = var.nsg_name
  logic_app_name      = "logic-soc-remediation"
  subscription_id     = var.subscription_id

}

module "sentinel" {
  source = "./modules/sentinel"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  subscription_id     = var.subscription_id
  logic_app_id        = module.remediation.logic_app_id
  logic_app           = module.remediation.logic_app
}
