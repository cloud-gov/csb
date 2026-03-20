locals {
  instance_sha                             = "ses-${substr(sha256(var.instance_id), 0, 16)}"
  base_name                                = "csb-aws-ses-${var.binding_id}"
  subscribe_bounce_notification_email      = (var.bounce_topic_arn != "" && var.notification_email != null)
  subscribe_complaint_notification_email   = (var.complaint_topic_arn != "" && var.notification_email != null)
  subscribe_delivery_notification_email    = (var.delivery_topic_arn != "" && var.notification_email != null)
  subscribed_email                         = ((local.subscribe_bounce_notification_email || local.subscribe_complaint_notification_email || local.subscribe_delivery_notification_email) ? var.notification_email : null)
  subscribe_bounce_notification_webhook    = (var.bounce_topic_arn != "" && var.notification_webhook != null)
  subscribe_complaint_notification_webhook = (var.complaint_topic_arn != "" && var.notification_webhook != null)
  subscribe_delivery_notification_webhook  = (var.delivery_topic_arn != "" && var.notification_webhook != null)
  subscribed_webhook                       = ((local.subscribe_bounce_notification_webhook || local.subscribe_complaint_notification_webhook || local.subscribe_delivery_notification_webhook) ? var.notification_webhook : null)
}

# Trivy: It is best practice to manage access via groups intead of by directly attaching
# policies to users. However, each binding may specify separate source IP constraints
# on sending, so we cannot use a group with a single policy for all users.
#trivy:ignore:AVD-AWS-0143
resource "aws_iam_user" "user" {
  name = local.base_name
  path = "/cf/"
}

resource "aws_iam_access_key" "access_key" {
  user = aws_iam_user.user.name
}

resource "aws_iam_user_policy" "user_policy" {
  name = local.base_name

  user = aws_iam_user.user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ses:SendEmail",
        "ses:SendRawEmail"
      ]
      Resource = [
        var.identity_arn,
        var.configuration_set_arn
      ]
    }]
  })
}

resource "aws_sns_topic_subscription" "bounce_subscription" {
  count = (local.subscribe_bounce_notification_email ? 1 : 0)

  topic_arn = var.bounce_topic_arn
  protocol  = "email"
  endpoint  = var.notification_email
}

resource "aws_sns_topic_subscription" "complaint_subscription" {
  count = (local.subscribe_complaint_notification_email ? 1 : 0)

  topic_arn = var.complaint_topic_arn
  protocol  = "email"
  endpoint  = var.notification_email
}

resource "aws_sns_topic_subscription" "delivery_subscription" {
  count = (local.subscribe_delivery_notification_email ? 1 : 0)

  topic_arn = var.delivery_topic_arn
  protocol  = "email"
  endpoint  = var.notification_email
}

resource "aws_sns_topic_subscription" "bounce_subscription_https" {
  count = (local.subscribe_bounce_notification_webhook ? 1 : 0)

  topic_arn = var.bounce_topic_arn
  protocol  = "https"
  endpoint  = var.notification_webhook
}

resource "aws_sns_topic_subscription" "complaint_subscription_https" {
  count = (local.subscribe_complaint_notification_webhook ? 1 : 0)

  topic_arn = var.complaint_topic_arn
  protocol  = "https"
  endpoint  = var.notification_webhook
}

resource "aws_sns_topic_subscription" "delivery_subscription_https" {
  count = (local.subscribe_delivery_notification_webhook ? 1 : 0)

  topic_arn = var.delivery_topic_arn
  protocol  = "https"
  endpoint  = var.notification_webhook
}
