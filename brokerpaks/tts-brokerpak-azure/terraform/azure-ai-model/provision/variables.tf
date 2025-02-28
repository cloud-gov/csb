# Azure authentication
variable "azure_tenant_id" {
  type = string
}

variable "azure_subscription_id" {
  type = string
}

variable "azure_client_id" {
  type = string
}

variable "azure_client_secret" {
  type = string
}

# User-provided service instance configuration
variable "location" {
  type    = string
  default = "eastus"
}

variable "model_name" {
  type        = string
  description = "The name of the AI model."
}

variable "model_version" {
  type        = string
  default     = "latest"
  description = "The version of the AI model."
}

# Computed variables
variable "labels" {
  type    = any
  default = {}
}
