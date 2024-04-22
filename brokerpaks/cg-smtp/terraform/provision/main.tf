locals {
  instance_id = "ses-${substr(sha256(var.instance_name), 0, 16)}"

  manage_domain = (var.domain == "" ? true : false)
  domain        = (local.manage_domain ? "${local.instance_id}.${var.default_domain}" : var.domain)
  txt_verification_record = {
    name    = "_amazonses"
    type    = "TXT"
    ttl     = "600"
    records = [aws_ses_domain_identity.identity.verification_token]
  }

  dmarc_verification_record = {
    name    = "_dmarc.${local.domain}"
    type    = "TXT"
    ttl     = "600"
    records = ["v=DMARC1; p=quarantine; rua=mailto:${var.email_receipt_error}; ruf=mailto:${var.email_receipt_error}"]
  }

  setting_mail_from = (var.mail_from_subdomain == "" ? false : true)
  mail_from_domain  = "${var.mail_from_subdomain}.${aws_ses_domain_identity.identity.domain}"

  mx_verification_record = {
    name    = local.mail_from_domain
    type    = "MX"
    ttl     = "600"
    records = ["10 feedback-smtp.${var.region}.amazonses.com"]
  }

  spf_verification_record = {
    name    = (local.setting_mail_from ? local.mail_from_domain : local.domain)
    type    = "TXT"
    ttl     = "600"
    records = ["v=spf1 include:amazonses.com -all"]
  }

  dkim_records = [for i, token in aws_ses_domain_dkim.dkim.dkim_tokens :
    {
      name    = "${token}._domainkey.${local.domain}"
      type    = "CNAME"
      ttl     = "600"
      records = ["${token}.dkim.amazonses.com"]
    }
  ]

  required_records = {
    txt_verification_record   = local.txt_verification_record
    dmarc_verification_record = local.dmarc_verification_record
    spf_verification_record   = local.spf_verification_record
    dkim_record_0             = local.dkim_records[0]
    dkim_record_1             = local.dkim_records[1]
    dkim_record_2             = local.dkim_records[2]
  }

  # Generate string output usable for pasting into HCL elsewhere if needed
  required_records_as_string = <<-EOT

  {%{for key, value in local.required_records}
    ${key} = {
      name    = "${value.name}"
      type    = "${value.type}"
      ttl     = "${value.ttl}"
      records = [%{for record in value.records}"${record}"%{endfor~}]
    } %{endfor}
    %{if local.setting_mail_from}mx_verification_record = {
      name    = "${local.mx_verification_record.name}"
      type    = "${local.mx_verification_record.type}"
      ttl     = "${local.mx_verification_record.ttl}"
      records = [%{for record in local.mx_verification_record.records}"${record}"%{endfor~}]
    } %{endif}
  }
  EOT

  # If no domain was specified, we manage the generated domain and need to
  # create the records ourselves
  required_records_flatter = {
    for key, value in local.required_records :
    key => {
      id     = key
      name   = value.name
      type   = value.type
      ttl    = value.ttl
      record = value.records[0]
    }
  }

  route53_records = (local.manage_domain ? local.required_records_flatter : {})

  # SNS topic locals
  bounce_topic_sns_arn    = (var.enable_feedback_notifications ? aws_sns_topic.bounce_topic[0].arn : "")
  complaint_topic_sns_arn = (var.enable_feedback_notifications ? aws_sns_topic.complaint_topic[0].arn : "")
  delivery_topic_sns_arn  = (var.enable_feedback_notifications ? aws_sns_topic.delivery_topic[0].arn : "")

  instructions = (local.manage_domain ? null : "Your SMTP service was provisioned, but is not yet verified. To verify your control of the ${var.domain} domain, create the 'required_records' provided here in the ${var.domain} zone before using the service.")
}

resource "aws_ses_domain_identity" "identity" {
  domain = local.domain
}

resource "aws_ses_domain_dkim" "dkim" {
  domain = aws_ses_domain_identity.identity.domain
}

resource "aws_ses_domain_mail_from" "mail_from" {
  count = (local.setting_mail_from ? 1 : 0)

  domain           = aws_ses_domain_identity.identity.domain
  mail_from_domain = local.mail_from_domain
}
