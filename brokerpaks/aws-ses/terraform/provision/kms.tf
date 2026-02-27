data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "feedback_topic_kms_key_policy" {
  statement {
    sid = "Enable IAM User Permissions"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws-us-gov:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions = [
      "kms:*"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid = "AllowSESToUseKMSKey"

    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }

    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_kms_key" "bounce_topic_kms_key" {
  count               = (var.enable_feedback_notifications ? 1 : 0)
  description         = "KMS key for SNS topic handling bounce notifications from SES"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.feedback_topic_kms_key_policy.json
}

resource "aws_kms_alias" "bounce_topic_kms_alias" {
  name          = "alias/${local.base_name}-bounce"
  target_key_id = aws_kms_key.bounce_topic_kms_key.key_id
}

resource "aws_kms_key" "complaint_topic_kms_key" {
  count               = (var.enable_feedback_notifications ? 1 : 0)
  description         = "KMS key for SNS topic handling complaint notifications from SES"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.feedback_topic_kms_key_policy.json
}

resource "aws_kms_alias" "complaint_topic_kms_alias" {
  name          = "alias/${local.base_name}-complaint"
  target_key_id = aws_kms_key.complaint_topic_kms_key.key_id
}

resource "aws_kms_key" "delivery_topic_kms_key" {
  count               = (var.enable_feedback_notifications ? 1 : 0)
  description         = "KMS key for SNS topic handling delivery notifications from SES"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.feedback_topic_kms_key_policy.json
}

resource "aws_kms_alias" "delivery_topic_kms_alias" {
  name          = "alias/${local.base_name}-delivery"
  target_key_id = aws_kms_key.delivery_topic_kms_key.key_id
}
