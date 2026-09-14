output "resource_group_name" {
  value = azurerm_resource_group.soc.name
}

output "vnet_name" {
  value = azurerm_virtual_network.soc.name
}

output "nsg_name" {
  value = azurerm_network_security_group.soc.name
}