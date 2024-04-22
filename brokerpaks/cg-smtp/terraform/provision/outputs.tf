output "region" { value = var.region }

output "required_records" {
  value = local.manage_domain ? null : local.required_records_as_string
}

output "email_receipt_error" {
  value = var.email_receipt_error
}

output "instructions" {
  value = local.instructions
}

output "domain_arn" {
  value = aws_ses_domain_identity.identity.arn
}

output "bounce_topic_arn" {
  value = local.bounce_topic_sns_arn
}

output "complaint_topic_arn" {
  value = local.complaint_topic_sns_arn
}

output "delivery_topic_arn" {
  value = local.delivery_topic_sns_arn
}
