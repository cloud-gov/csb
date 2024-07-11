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

variable "domain_arn" {
  type = string
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