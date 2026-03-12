locals {
  bounce_topic_name    = "${local.base_name}-bounce"
  complaint_topic_name = "${local.base_name}-complaint"
  delivery_topic_name  = "${local.base_name}-delivery"
}

# Create SNS topic for bounce messages
data "aws_iam_policy_document" "bounce_topic_policy_document" {
  count     = (var.enable_feedback_notifications ? 1 : 0)
  policy_id = "${local.bounce_topic_name}-policy"

  statement {
    sid    = "AllowSESAccess"
    effect = "Allow"

    actions = [
      "SNS:Publish"
    ]

    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }

    resources = [
      "arn:${data.aws_partition.current.partition}:sns:${var.aws_region_govcloud}:${data.aws_caller_identity.current.account_id}:${local.bounce_topic_name}"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"

      values = [
        data.aws_caller_identity.current.account_id,
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"

      values = [
        "arn:${data.aws_partition.current.partition}:ses:${var.aws_region_govcloud}:${data.aws_caller_identity.current.account_id}:configuration-set/${aws_sesv2_configuration_set.config.configuration_set_name}"
      ]
    }
  }
}

resource "aws_sns_topic" "bounce_topic" {
  count = (var.enable_feedback_notifications ? 1 : 0)
  name  = local.bounce_topic_name

  kms_master_key_id = local.bounce_topic_kms_key_alias
}

resource "aws_sns_topic_policy" "bounce_topic_policy" {
  count  = (var.enable_feedback_notifications ? 1 : 0)
  arn    = aws_sns_topic.bounce_topic[0].arn
  policy = data.aws_iam_policy_document.bounce_topic_policy_document[0].json
}

# Create SNS topic for complaint messages
data "aws_iam_policy_document" "complaint_topic_policy_document" {
  count     = (var.enable_feedback_notifications ? 1 : 0)
  policy_id = "${local.complaint_topic_name}-policy"

  statement {
    sid    = "AllowSESAccess"
    effect = "Allow"

    actions = [
      "SNS:Publish"
    ]

    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }

    resources = [
      "arn:${data.aws_partition.current.partition}:sns:${var.aws_region_govcloud}:${data.aws_caller_identity.current.account_id}:${local.complaint_topic_name}"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"

      values = [
        data.aws_caller_identity.current.account_id,
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"

      values = [
        "arn:${data.aws_partition.current.partition}:ses:${var.aws_region_govcloud}:${data.aws_caller_identity.current.account_id}:configuration-set/${aws_sesv2_configuration_set.config.configuration_set_name}"
      ]
    }
  }
}

resource "aws_sns_topic" "complaint_topic" {
  count = (var.enable_feedback_notifications ? 1 : 0)
  name  = local.complaint_topic_name

  kms_master_key_id = local.complaint_topic_kms_key_alias
}

resource "aws_sns_topic_policy" "complaint_topic_policy" {
  count  = (var.enable_feedback_notifications ? 1 : 0)
  arn    = aws_sns_topic.complaint_topic[0].arn
  policy = data.aws_iam_policy_document.complaint_topic_policy_document[0].json
}

# Create SNS topic for delivery messages
data "aws_iam_policy_document" "delivery_topic_policy_document" {
  count     = (var.enable_feedback_notifications ? 1 : 0)
  policy_id = "${local.delivery_topic_name}-policy"

  statement {
    sid    = "AllowSESAccess"
    effect = "Allow"

    actions = [
      "SNS:Publish"
    ]

    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }

    resources = [
      "arn:${data.aws_partition.current.partition}:sns:${var.aws_region_govcloud}:${data.aws_caller_identity.current.account_id}:${local.delivery_topic_name}"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"

      values = [
        data.aws_caller_identity.current.account_id,
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"

      values = [
        "arn:${data.aws_partition.current.partition}:ses:${var.aws_region_govcloud}:${data.aws_caller_identity.current.account_id}:configuration-set/${aws_sesv2_configuration_set.config.configuration_set_name}"
      ]
    }
  }
}

resource "aws_sns_topic" "delivery_topic" {
  count = (var.enable_feedback_notifications ? 1 : 0)
  name  = local.delivery_topic_name

  kms_master_key_id = local.delivery_topic_kms_key_alias
}

resource "aws_sns_topic_policy" "delivery_topic_policy" {
  count  = (var.enable_feedback_notifications ? 1 : 0)
  arn    = aws_sns_topic.delivery_topic[0].arn
  policy = data.aws_iam_policy_document.delivery_topic_policy_document[0].json
}
