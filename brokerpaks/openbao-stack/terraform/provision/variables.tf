variable "instance_id" {
  type = string
  validation {
    condition     = can(regex("^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$", var.instance_id))
    error_message = "A platform-supplied service-instance GUID is required."
  }
}

variable "organization_guid" {
  type = string
}

variable "space_guid" {
  type = string
}

variable "broker_app_guid" {
  description = "Broker app GUID supplied from VCAP_APPLICATION at broker startup."
  type        = string
  validation {
    condition     = can(regex("^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$", var.broker_app_guid))
    error_message = "The broker must supply its cloud foundry application GUID."
  }
}

variable "management_credential_ref" {
  description = "Broker-private SSM parameter name for the stack root token."
  type        = string
}

variable "dev_config" {
  description = "Non-secret operator settings from OPENBAO_DEV_CONFIG on the dev broker"
  type        = string
  validation {
    condition     = can(keys(jsondecode(var.dev_config)))
    error_message = "The broker must supply OPENBAO_DEV_CONFIG as a JSON object."
  }
}
