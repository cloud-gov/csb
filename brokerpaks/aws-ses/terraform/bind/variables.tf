// Provider credentials
variable "aws_access_key_id_govcloud" {
  type = string
}

variable "aws_secret_access_key_govcloud" {
  type      = string
  sensitive = true
}

variable "aws_region_govcloud" {
  type = string
}

// Brokerpak configuration
variable "binding_id" {
  type = string
}

variable "instance_id" {
  type        = string
  description = "The identifier for the instance, which together with the Plan ID and Service ID is unique. When CAPI sends the provision request, this is a GUID."
}

variable "region" {
  type        = string
  description = "The AWS region in which to create the SES user and credentials."
}

variable "configuration_set_arn" {
  type        = string
  description = "ARN of the SES Configuration Set associated with the identity."
}

variable "identity_arn" {
  type        = string
  description = "ARN of the SES identity."
}

variable "source_ips" {
  type = list(string)
}

variable "bounce_topic_arn" {
  type    = string
  default = ""
}

variable "complaint_topic_arn" {
  type    = string
  default = ""
}

variable "delivery_topic_arn" {
  type    = string
  default = ""
}

variable "notification_webhook" {
  type    = string
  default = ""
}

variable "context" {
  type        = any
  description = "Cloud Foundry context object from provision call. Useful for tagging resources."
}

variable "service_offering_name" {
  type        = string
  description = "Name of the Cloud Foundry service offering. Used for tagging."
}

variable "service_plan_name" {
  type        = string
  description = "Name of the Cloud Foundry service plan. Used for tagging."
}

variable "cloud_gov_environment" {
  type        = string
  description = "The cloud.gov environment the broker is deployed in. For example: local, development, staging, or production."
}
