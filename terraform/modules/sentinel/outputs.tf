output "log_analytics_workspace_id" {
  value       = azurerm_log_analytics_workspace.soc.id
  description = "Resource ID du Log Analytics Workspace"
}

output "sentinel_alert_rule_id" {
  value       = azurerm_sentinel_alert_rule_scheduled.nsg_ssh_alert.id
  description = "Resource ID de la règle d'alerte Sentinel"
}