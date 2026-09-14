output "resource_group_name" {
  value = data.azurerm_resource_group.rg.name
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

output "vnet_name" {
  value = module.infrastructure.vnet_name
}

output "vnet_id" {
  value = module.infrastructure.vnet_id
}

output "nsg_name" {
  value = module.infrastructure.nsg_name
}

output "nsg_id" {
  value = module.infrastructure.nsg_id
}
