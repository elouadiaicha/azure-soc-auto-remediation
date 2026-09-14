variable "resource_group_name" {
  type        = string
  description = "Nom du Resource Group dans lequel déployer le SOC"
}

variable "location" {
  type        = string
  description = "Région Azure (ex: westeurope)"
}

variable "workspace_name" {
  type        = string
  default     = "law-soc-sentinel"
  description = "Nom du Log Analytics Workspace"
}

variable "target_nsg_rule_name" {
  type        = string
  default     = "Allow-SSH-Internet-Demo"
  description = "Nom de la règle NSG sensible ciblée par la règle de détection"
}

variable "subscription_id" {
  type        = string
  description = "ID de la souscription Azure pour la collecte des logs AzureActivity"
}