data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

module "sns_topic" {
  source  = "terraform-aws-modules/sns/aws"
  version = "7.1.1"

  name       = var.topic_name
  fifo_topic = false

  # Encrypt SNS messages using the existing customer-managed KMS key
  kms_master_key_id = var.kms_key_arn

  # Manage the topic policy explicitly
  create_topic_policy = true

  # Disable the upstream module's default wildcard-principal policy
  enable_default_topic_policy = false

  # Restrict topic access to principals in this AWS account
  topic_policy_statements = merge(
    {
      account_access = {
        sid    = "AllowAccountAccess"
        effect = "Allow"

        actions = [
          "sns:GetTopicAttributes",
          "sns:ListSubscriptionsByTopic",
          "sns:Publish",
          "sns:Subscribe"
        ]

        principals = [
          {
            type = "AWS"
            identifiers = [
              "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
            ]
          }
        ]
      }
    },

    var.allow_cloudwatch_publish ? {
      cloudwatch_publish = {
        sid    = "AllowCloudWatchAlarmPublish"
        effect = "Allow"

        actions = [
          "sns:Publish"
        ]

        principals = [
          {
            type        = "Service"
            identifiers = ["cloudwatch.amazonaws.com"]
          }
        ]

        condition = [
          {
            test     = "StringEquals"
            variable = "aws:SourceAccount"
            values   = [data.aws_caller_identity.current.account_id]
          },
          {
            test     = "ArnLike"
            variable = "aws:SourceArn"
            values = [
              "arn:${data.aws_partition.current.partition}:cloudwatch:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:alarm:*"
            ]
          }
        ]
      }
    } : {}
  )

  # No subscriptions yet
  create_subscription = false

  tags = var.tags
}