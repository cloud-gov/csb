locals {
  bounce_topic_kms_key_alias    = "alias/${local.base_name}-bounce"
  complaint_topic_kms_key_alias = "alias/${local.base_name}-complaint"
  delivery_topic_kms_key_alias  = "alias/${local.base_name}-delivery"
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "bounce_topic_kms_key_policy" {
  count = (var.enable_feedback_notifications ? 1 : 0)

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

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:aws:sns:topicArn"
      values   = [aws_sns_topic.bounce_topic[0].arn]
    }
  }

  statement {
    sid = "SNSTopicAccess"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]

    resources = [
      "*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.bounce_topic[0].arn]
    }
  }
}

resource "aws_kms_key" "bounce_topic_kms_key" {
  count               = (var.enable_feedback_notifications ? 1 : 0)
  description         = "KMS key for SNS topic handling bounce notifications from SES"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.bounce_topic_kms_key_policy[0].json
}

resource "aws_kms_alias" "bounce_topic_kms_alias" {
  count         = (var.enable_feedback_notifications ? 1 : 0)
  name          = "alias/${local.base_name}-bounce"
  target_key_id = aws_kms_key.bounce_topic_kms_key[0].key_id
}

data "aws_iam_policy_document" "complaint_topic_kms_key_policy" {
  count = (var.enable_feedback_notifications ? 1 : 0)
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

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:aws:sns:topicArn"
      values   = [aws_sns_topic.complaint_topic[0].arn]
    }
  }

  statement {
    sid = "SNSTopicAccess"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]

    resources = [
      "*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.complaint_topic[0].arn]
    }
  }
}

resource "aws_kms_key" "complaint_topic_kms_key" {
  count               = (var.enable_feedback_notifications ? 1 : 0)
  description         = "KMS key for SNS topic handling complaint notifications from SES"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.complaint_topic_kms_key_policy[0].json
}

resource "aws_kms_alias" "complaint_topic_kms_alias" {
  count         = (var.enable_feedback_notifications ? 1 : 0)
  name          = "alias/${local.base_name}-complaint"
  target_key_id = aws_kms_key.complaint_topic_kms_key[0].key_id
}

data "aws_iam_policy_document" "delivery_topic_kms_key_policy" {
  count = (var.enable_feedback_notifications ? 1 : 0)
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

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:aws:sns:topicArn"
      values   = [aws_sns_topic.delivery_topic[0].arn]
    }
  }

  statement {
    sid = "SNSTopicAccess"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]

    resources = [
      "*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.delivery_topic[0].arn]
    }
  }
}


resource "aws_kms_key" "delivery_topic_kms_key" {
  count               = (var.enable_feedback_notifications ? 1 : 0)
  description         = "KMS key for SNS topic handling delivery notifications from SES"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.delivery_topic_kms_key_policy[0].json
}

resource "aws_kms_alias" "delivery_topic_kms_alias" {
  count         = (var.enable_feedback_notifications ? 1 : 0)
  name          = "alias/${local.base_name}-delivery"
  target_key_id = aws_kms_key.delivery_topic_kms_key[0].key_id
}
