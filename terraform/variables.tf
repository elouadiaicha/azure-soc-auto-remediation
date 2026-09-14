variable "location" {
  description = "Region Azure"
  type        = string
  default     = "francecentral"
}

variable "resource_group_name" {
  description = "Resource Group du projet SOC"
  type        = string
  default     = "rg-DZ"
}

variable "vnet_name" {
  description = "Nom du VNet"
  type        = string
  default     = "vnet-soc-demo"
}

variable "nsg_name" {
  description = "Nom du Network Security Group"
  type        = string
  default     = "nsg-soc-demo"
}

variable "subscription_id" {
  description = "ID de la subscription Azure"
  type        = string
  default     = "5e683e0f-b00c-48d6-9769-5aaf598de8f1"
}