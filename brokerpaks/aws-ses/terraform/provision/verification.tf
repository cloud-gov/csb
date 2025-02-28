# Get the configured default DNS Zone
data "aws_route53_zone" "parent_zone" {
  provider = aws.commercial
  count    = (local.manage_domain ? 1 : 0)
  name     = var.default_domain
}

# Create Hosted Zone for the specific subdomain name
resource "aws_route53_zone" "instance_zone" {
  provider = aws.commercial
  count    = (local.manage_domain ? 1 : 0)
  comment  = "Created for a customer using the Cloud Service Broker and AWS SES brokerpak."

  name          = local.domain
  force_destroy = true
}

# Create the NS record in the parent zone for the instance zone
resource "aws_route53_record" "instance_ns" {
  provider = aws.commercial
  count    = (local.manage_domain ? 1 : 0)

  zone_id = data.aws_route53_zone.parent_zone[0].zone_id
  name    = var.instance_id
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.instance_zone[0].name_servers
}

# Create any necessary records in the instance_zone
resource "aws_route53_record" "records" {
  provider = aws.commercial
  for_each = local.route53_records

  name    = each.value.name
  type    = each.value.type
  ttl     = each.value.ttl
  records = [each.value.record]

  zone_id = aws_route53_zone.instance_zone[0].zone_id
}

# Create MX record if needed
resource "aws_route53_record" "mail_from_mx_record" {
  provider = aws.commercial
  count    = (local.manage_domain && local.setting_mail_from ? 1 : 0)

  name    = local.mx_verification_record.name
  type    = local.mx_verification_record.type
  ttl     = local.mx_verification_record.ttl
  records = local.mx_verification_record.records

  zone_id = aws_route53_zone.instance_zone[0].zone_id
}
