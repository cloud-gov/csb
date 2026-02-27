data "aws_caller_identity" "current" {}

resource "aws_kms_key" "bounce_topic_kms_key" {
  count               = (var.enable_feedback_notifications ? 1 : 0)
  description         = "KMS key for SNS topic handling bounce notifications from SES"
  enable_key_rotation = true
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "AllowSES"
    Statement = [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws-us-gov:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        "Sid" : "AllowSESToUseKMSKey",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ses.amazonaws.com"
        },
        "Action" : [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_kms_alias" "bounce_topic_kms_alias" {
  name          = "alias/${local.base_name}-bounce"
  target_key_id = bounce_topic_kms_key.a.key_id
}

resource "aws_kms_key" "complaint_topic_kms_key" {
  count               = (var.enable_feedback_notifications ? 1 : 0)
  description         = "KMS key for SNS topic handling complaint notifications from SES"
  enable_key_rotation = true
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "AllowSES"
    Statement = [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws-us-gov:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        "Sid" : "AllowSESToUseKMSKey",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ses.amazonaws.com"
        },
        "Action" : [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_kms_alias" "complaint_topic_kms_alias" {
  name          = "alias/${local.base_name}-complaint"
  target_key_id = complaint_topic_kms_key.a.key_id
}
