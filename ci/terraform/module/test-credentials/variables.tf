
variable "deployer_service_name" {
  type        = string
  description = "Name of service account used to manage test resources"
}

variable "deployer_service_key_name" {
  type        = string
  description = "Name of service key for account used to manage test resources"
}

variable "org_name" {
  type        = string
  description = "Name of CF organization where test resources are created"
}

variable "space_name" {
  type        = string
  description = "Name of CF space where test resources are created"
}
