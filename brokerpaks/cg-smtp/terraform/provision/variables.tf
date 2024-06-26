variable "domain" {
  type        = string
  description = "Domain from which to send mail"
  default     = ""
}

variable "default_domain" {
  type        = string
  description = "Computed. Fallback domain to use if none was supplied."
}

variable "instance_name" {
  type = string
}

variable "region" {
  type        = string
  description = "The AWS region in which to create the SES instance."
}

variable "dmarc_report_uri_aggregate" {
  type        = string
  description = "The mailto URI to which DMARC aggregate reports should be sent. For example, 'mailto:dmarc@example.gov'."
}

variable "dmarc_report_uri_failure" {
  type        = string
  description = "To mailto URI to which to which DMARC individual message failure reports should be sent. For example, 'mailto:dmarc@example.gov'."
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
