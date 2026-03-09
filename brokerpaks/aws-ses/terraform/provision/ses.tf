resource "aws_sesv2_email_identity" "identity" {
  configuration_set_name = aws_sesv2_configuration_set.config.configuration_set_name
  email_identity         = local.domain
}

resource "aws_sesv2_email_identity_mail_from_attributes" "mail_from" {
  count = (local.setting_mail_from ? 1 : 0)

  email_identity   = aws_sesv2_email_identity.identity.email_identity
  mail_from_domain = local.mail_from_domain
}

resource "aws_sesv2_configuration_set" "config" {
  configuration_set_name = local.base_name

  delivery_options {
    tls_policy = "REQUIRE"
  }
  reputation_options {
    reputation_metrics_enabled = true
  }
  suppression_options {
    suppressed_reasons = ["BOUNCE", "COMPLAINT"]
  }

  lifecycle {
    # The csb-helper will disable sending on an identity if its reputation
    # metrics exceed a certain threshold. To avoid the CSB accidentally
    # overwriting this change, ignore changes to the sending_enabled field.
    ignore_changes = [sending_options["sending_enabled"]]
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

resource "aws_sesv2_configuration_set_event_destination" "complaint" {
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
