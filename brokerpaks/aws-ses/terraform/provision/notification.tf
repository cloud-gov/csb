# Create SNS topic for bounce messages
# Trivy: It is best practice to encrypt with customer-managed keys so permissions can be managed more granularly, but we have not implemented a system for doing so yet at CG.
#trivy:ignore:AVD-AWS-0136
resource "aws_sns_topic" "bounce_topic" {
  count = (var.enable_feedback_notifications ? 1 : 0)
  name  = "${local.base_name}-bounce"

  # Use an AWS-managed key for topic encryption.
  kms_master_key_id = "alias/aws/sns"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_sesv2_configuration_set_event_destination" "bounce" {
  count = (var.enable_feedback_notifications ? 1 : 0)

  configuration_set_name = aws_sesv2_configuration_set.config.configuration_set_name
  event_destination_name = "${local.base_name}-bounce"

  event_destination {
    # Valid types: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sesv2_configuration_set_event_destination#matching_event_types
    matching_event_types = ["BOUNCE"]
    sns_destination {
      topic_arn = aws_sns_topic.bounce_topic[0].arn
    }
  }
}

# Create SNS topic for complaint messages
# Trivy: It is best practice to encrypt with customer-managed keys so permissions can be managed more granularly, but we have not implemented a system for doing so yet at CG.
#trivy:ignore:AVD-AWS-0136
resource "aws_sns_topic" "complaint_topic" {
  count = (var.enable_feedback_notifications ? 1 : 0)
  name  = "${local.base_name}-complaint"

  # Use an AWS-managed key for topic encryption.
  kms_master_key_id = "alias/aws/sns"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_sesv2_configuration_set_event_destination" "name" {
  count = (var.enable_feedback_notifications ? 1 : 0)

  configuration_set_name = aws_sesv2_configuration_set.config.configuration_set_name
  event_destination_name = "${local.base_name}-complaint"
  event_destination {
    matching_event_types = ["COMPLAINT"]
    sns_destination {
      topic_arn = aws_sns_topic.complaint_topic[0].arn
    }
  }
}

# Create SNS topic for delivery messages
# Trivy: It is best practice to encrypt with customer-managed keys so permissions can be managed more granularly, but we have not implemented a system for doing so yet at CG.
#trivy:ignore:AVD-AWS-0136
resource "aws_sns_topic" "delivery_topic" {
  count = (var.enable_feedback_notifications ? 1 : 0)
  name  = "${local.base_name}-delivery"

  # Use an AWS-managed key for topic encryption.
  kms_master_key_id = "alias/aws/sns"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_sesv2_configuration_set_event_destination" "delivery" {
  count = (var.enable_feedback_notifications ? 1 : 0)

  configuration_set_name = aws_sesv2_configuration_set.config.configuration_set_name
  event_destination_name = "${local.base_name}-delivery"
  event_destination {
    matching_event_types = ["DELIVERY"]
    sns_destination {
      topic_arn = aws_sns_topic.delivery_topic[0].arn
    }
  }
  # include_original_headers = true # todo: This was on the v1 resource.
}
