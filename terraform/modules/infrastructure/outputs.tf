output "resource_group_name" {
  value = data.azurerm_resource_group.rg.name
}

output "resource_group_id" {
  value = data.azurerm_resource_group.rg.id
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "nsg_name" {
  value = azurerm_network_security_group.nsg.name
}

output "nsg_id" {
  value = azurerm_network_security_group.nsg.id
}