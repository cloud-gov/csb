locals {
  instance_id                      = "ses-${substr(sha256(var.instance_name), 0, 16)}"
  user_name                        = "${local.instance_id}-${var.user_name}"
  subscribe_bounce_notification    = (var.bounce_topic_arn != "" && var.notification_webhook != "")
  subscribe_complaint_notification = (var.complaint_topic_arn != "" && var.notification_webhook != "")
  subscribe_delivery_notification  = (var.delivery_topic_arn != "" && var.notification_webhook != "")
  subscribed_webhook               = ((local.subscribe_bounce_notification || local.subscribe_complaint_notification || local.subscribe_delivery_notification) ? var.notification_webhook : null)
}

resource "aws_iam_user" "user" {
  name = local.user_name
  path = "/cf/"
}

resource "aws_iam_access_key" "access_key" {
  user = aws_iam_user.user.name
}

resource "aws_ses_identity_policy" "user_policy" {
  identity = var.domain_arn
  name     = format("%s-p", local.user_name)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ses:SendEmail",
        "ses:SendRawEmail"
      ]
      Resource = var.domain_arn
      Principal = {
        AWS = [
          aws_iam_user.user.arn
        ]
      }
      Condition = {
        "ForAnyValue:IpAddress" = {
          "aws:SourceIp" = var.source_ips
        }
      }
    }]
  })
}

resource "aws_sns_topic_subscription" "bounce_subscription" {
  count = (local.subscribe_bounce_notification ? 1 : 0)

  topic_arn = var.bounce_topic_arn
  protocol  = "https"
  endpoint  = var.notification_webhook
}

resource "aws_sns_topic_subscription" "complaint_subscription" {
  count = (local.subscribe_complaint_notification ? 1 : 0)

  topic_arn = var.complaint_topic_arn
  protocol  = "https"
  endpoint  = var.notification_webhook
}

resource "aws_sns_topic_subscription" "delivery_subscription" {
  count = (local.subscribe_delivery_notification ? 1 : 0)

  topic_arn = var.delivery_topic_arn
  protocol  = "https"
  endpoint  = var.notification_webhook
}
