variable "resource_group_name" {
  description = "Nom du Resource Group"
  type        = string
}

variable "location" {
  description = "Region Azure"
  type        = string
}

variable "nsg_name" {
  description = "Nom du Network Security Group a proteger"
  type        = string
}

variable "logic_app_name" {
  description = "Nom de la Logic App de remediation"
  type        = string
  default     = "logic-soc-remediation"
}

variable "subscription_id" {
  description = "ID de la souscription Azure"
  type        = string
}
