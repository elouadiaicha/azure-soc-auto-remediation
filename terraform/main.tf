module "infrastructure" {
  source = "./modules/infrastructure"

  resource_group_name = var.resource_group_name
  vnet_name           = var.vnet_name
  nsg_name            = var.nsg_name
}