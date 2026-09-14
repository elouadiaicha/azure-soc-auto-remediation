output "resource_group_name" {
  value = data.azurerm_resource_group.soc.name
}

output "vnet_name" {
  value = var.vnet_name
}

output "nsg_name" {
  value = var.nsg_name
}

output "logic_app_name" {
  value = module.remediation.logic_app_name
}

output "logic_app_id" {
  value = module.remediation.logic_app_id
}

output "logic_app_managed_identity_principal_id" {
  value = module.remediation.managed_identity_principal_id
}
