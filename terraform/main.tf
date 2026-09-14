module "infrastructure" {
  source = "./modules/infrastructure"

  resource_group_name = var.resource_group_name
  vnet_name           = var.vnet_name
  nsg_name            = var.nsg_name
}
data "azurerm_resource_group" "soc" {
  name = var.resource_group_name
}

module "sentinel" {
  source = "./modules/sentinel"

  resource_group_name  = data.azurerm_resource_group.soc.name
  location             = var.location
  subscription_id      = var.subscription_id
}
