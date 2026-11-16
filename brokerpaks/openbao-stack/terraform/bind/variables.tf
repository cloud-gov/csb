variable "instance_id" {
  type = string
}
variable "binding_id" {
  type = string
}
variable "app_guid" {
  type = string
  description = "Trusted app GUID; empty for app-less credential-client binding"
}
variable "organization_guid" {
  type = string
}
variable "space_guid" {
  type = string
}
variable "endpoint" {
  type = string
}
variable "mount" {
  type = string
}
variable "management_credential_ref" {
  type = string
  description = "Broker-private reference, not a credential or consumer output."
}
variable "path_prefix" {
  type = string
  validation {
    condition = length(var.path_prefix) <= 128 && can(regex("^[A-Za-z0-9_-]+(/[A-Za-z0-9_-]+)*$", var.path_prefix))
    error_message = "path_prefix must be a literal relative path of at most 128 characters, without wildcards or traversal"
  }
}
variable "access" {
  type = string
  default = "read-only"
  validation {
    condition = contains(["read-only", "read-write"], var.access)
    error_message = "access must be read-only or read-write."
  }
}