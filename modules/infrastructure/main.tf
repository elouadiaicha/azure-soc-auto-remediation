data "azurerm_resource_group" "soc" {
  name = var.resource_group_name
}

resource "azurerm_virtual_network" "soc" {
  name                = var.vnet_name
  location            = data.azurerm_resource_group.soc.location
  resource_group_name = data.azurerm_resource_group.soc.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_network_security_group" "soc" {
  name                = var.nsg_name
  location            = data.azurerm_resource_group.soc.location
  resource_group_name = data.azurerm_resource_group.soc.name
}