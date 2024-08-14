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
variable "user_name" {
  type = string
}

variable "instance_name" {
  type    = string
  default = ""
}

variable "region" {
  type        = string
  description = "The AWS region in which to create the SES user and credentials."
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
