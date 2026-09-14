output "logic_app_id" {
  description = "ID de la Logic App"
  value       = azurerm_logic_app_workflow.remediation.id
}

output "logic_app_name" {
  description = "Nom de la Logic App"
  value       = azurerm_logic_app_workflow.remediation.name
}

output "managed_identity_principal_id" {
  description = "Principal ID de la Managed Identity de la Logic App"
  value       = azurerm_logic_app_workflow.remediation.identity[0].principal_id
}
