variable "instance_id" {
    type = string
    validation {
      condition = can(regex("^[0-9a-f-]{36}$", var.instance_id))
      error_message = "A platform-supplied service-instance GUID is required."
    }
}

variable "organization_guid" {
    type = string
    validation {
        condition = length(var.organization_guid) > 0
        error_message = "The platform organization GUID must be supplied"
    }
}

variable "space_guid" {
  type = string
  validation {
    condition = length(var.space_guid) > 0
    error_message = "The platform space GUID must be supplied"
  }
}

variable "management_credential_ref" {
  type = string
  description = "Broker-private credential reference, never a root token and never an output"
  validation {
    condition = length(var.management_credential_ref) > 0
    error_message = "A broker-controlled credential reference is required."
  }
}
