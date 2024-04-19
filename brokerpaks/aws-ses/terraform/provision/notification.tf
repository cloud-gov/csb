# Create SNS topic for bounce messages
resource "aws_sns_topic" "bounce_topic" {
  count = (var.enable_feedback_notifications ? 1 : 0)
  name  = "${var.instance_name}-bounce"
}

# Connect bounce notifications to the bounce SNS topic
resource "aws_ses_identity_notification_topic" "bounce" {
  count                    = (var.enable_feedback_notifications ? 1 : 0)
  topic_arn                = aws_sns_topic.bounce_topic[0].arn
  notification_type        = "Bounce"
  identity                 = aws_ses_domain_identity.identity.arn
  include_original_headers = true
}

# Create SNS topic for complaint messages
resource "aws_sns_topic" "complaint_topic" {
  count = (var.enable_feedback_notifications ? 1 : 0)
  name  = "${var.instance_name}-complaint"
}

# Connect complaint notifications to the complaint SNS topic
resource "aws_ses_identity_notification_topic" "complaint" {
  count                    = (var.enable_feedback_notifications ? 1 : 0)
  topic_arn                = aws_sns_topic.complaint_topic[0].arn
  notification_type        = "Complaint"
  identity                 = aws_ses_domain_identity.identity.arn
  include_original_headers = true
}

# Create SNS topic for delivery messages
resource "aws_sns_topic" "delivery_topic" {
  count = (var.enable_feedback_notifications ? 1 : 0)
  name  = "${var.instance_name}-delivery"
}

# Connect delivery notifications to the delivery SNS topic
resource "aws_ses_identity_notification_topic" "delivery" {
  count                    = (var.enable_feedback_notifications ? 1 : 0)
  topic_arn                = aws_sns_topic.delivery_topic[0].arn
  notification_type        = "Delivery"
  identity                 = aws_ses_domain_identity.identity.arn
  include_original_headers = true
}
