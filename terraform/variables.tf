variable "location" {
  description = "Region Azure"
  type        = string
  default     = "francecentral"
}

variable "resource_group_name" {
  description = "Resource Group du projet SOC"
  type        = string
  default     = "rg-soc-demo"
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