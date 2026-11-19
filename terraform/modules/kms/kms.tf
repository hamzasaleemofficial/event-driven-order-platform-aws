data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.1"

  description = var.description

  key_usage               = "ENCRYPT_DECRYPT"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  multi_region            = false

  # Preserve the default account-level key policy.
  enable_default_policy = true

  # Optionally permit CloudWatch alarms to use the key for SNS encryption.
  key_statements = var.allow_cloudwatch_alarm_encryption ? [
    {
      sid    = "AllowCloudWatchAlarmEncryption"
      effect = "Allow"

      actions = [
        "kms:GenerateDataKey*",
        "kms:Decrypt"
      ]

      resources = ["*"]

      principals = [
        {
          type        = "Service"
          identifiers = ["cloudwatch.amazonaws.com"]
        }
      ]
    }
  ] : []

  aliases = [var.alias_name]

  tags = var.tags
}