variable "resource_group_name" {
  type    = string
  default = "rg-DZ"
}

variable "vnet_name" {
  type    = string
  default = "vnet-soc-demo"
}

variable "nsg_name" {
  type    = string
  default = "nsg-soc-demo"
  description = "Nom du Network Security Group"
}

variable "subscription_id" {
  description = "ID de la subscription Azure"
  type        = string
  default     = "5e683e0f-b00c-48d6-9769-5aaf598de8f1"
}