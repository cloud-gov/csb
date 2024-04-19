variable "domain" {
  type        = string
  description = "Domain from which to send mail"
  default     = ""
}

variable "default_domain" {
  type        = string
  description = "Fallback domain to use if none was supplied"
  default     = "example.gov"
}

variable "instance_name" {
  type = string
}

variable "region" {
  type = string
}

variable "email_receipt_error" {
  type = string
}

variable "labels" {
  type    = map(any)
  default = {}
}

variable "enable_feedback_notifications" {
  type        = bool
  description = "Toggle whether to create SNS topics for feedback notifications"
  default     = false
}

variable "mail_from_subdomain" {
  type        = string
  description = "Subdomain to set as the mail-from value"
  default     = ""
}
