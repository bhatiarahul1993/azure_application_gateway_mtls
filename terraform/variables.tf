variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "et-appgw-poc"
}

variable "location" {
  description = "The Azure region to deploy resources"
  type        = string
  default     = "EastUS2"
}