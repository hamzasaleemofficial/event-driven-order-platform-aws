data "aws_region" "current" {}

data "aws_iam_policy_document" "service_deployment" {
  statement {
    sid = "ReadLambdaFunctions"

    actions = [
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:GetFunctionCodeSigningConfig",
      "lambda:GetFunctionConcurrency",
      "lambda:GetPolicy",
      "lambda:ListTags",
      "lambda:ListVersionsByFunction"
    ]

    resources = var.lambda_function_arns
  }

  statement {
    sid = "UpdateLambdaFunctions"

    actions = [
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "lambda:TagResource",
      "lambda:UntagResource"
    ]

    resources = var.lambda_function_arns
  }

  statement {
    sid = "ReadDynamoDBTable"

    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:DescribeContinuousBackups",
      "dynamodb:DescribeTimeToLive",
      "dynamodb:ListTagsOfResource"
    ]

    resources = [var.orders_table_arn]
  }

  statement {
    sid = "UpdateDynamoDBTable"

    actions = [
      "dynamodb:UpdateTable",
      "dynamodb:UpdateContinuousBackups",
      "dynamodb:UpdateTimeToLive",
      "dynamodb:TagResource",
      "dynamodb:UntagResource"
    ]

    resources = [var.orders_table_arn]
  }

  statement {
    sid = "ReadSQSQueues"

    actions = [
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ListQueueTags"
    ]

    resources = var.sqs_queue_arns
  }

  statement {
    sid = "UpdateSQSQueues"

    actions = [
      "sqs:SetQueueAttributes",
      "sqs:TagQueue",
      "sqs:UntagQueue"
    ]

    resources = var.sqs_queue_arns
  }

  statement {
    sid = "ReadSNSTopics"

    actions = [
      "sns:GetTopicAttributes",
      "sns:GetSubscriptionAttributes",
      "sns:ListTagsForResource",
      "sns:ListSubscriptionsByTopic"
    ]

    resources = var.sns_topic_arns
  }

  statement {
    sid = "UpdateSNSTopics"

    actions = [
      "sns:SetTopicAttributes",
      "sns:TagResource",
      "sns:UntagResource"
    ]

    resources = var.sns_topic_arns
  }

  statement {
    sid = "ReadKMSKey"

    actions = [
      "kms:DescribeKey",
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
      "kms:ListResourceTags"
    ]

    resources = [var.kms_key_arn]
  }

  statement {
    sid = "ListKMSAliases"

    actions = [
      "kms:ListAliases"
    ]

    resources = ["*"]
  }

  statement {
    sid = "ReadAPIGateway"

    actions = [
      "apigateway:GET"
    ]

    resources = [
      var.api_gateway_arn,
      "${var.api_gateway_arn}/*"
    ]
  }

  statement {
    sid = "UpdateAPIGateway"

    actions = [
      "apigateway:PATCH"
    ]

    resources = [
      var.api_gateway_arn,
      "${var.api_gateway_arn}/*"
    ]
  }

  statement {
    sid = "DescribeCloudWatchLogGroups"

    actions = [
      "logs:DescribeLogGroups"
    ]

    resources = ["*"]
  }

  statement {
    sid = "ReadCloudWatchLogGroups"

    actions = [
      "logs:ListTagsForResource",
      "logs:ListTagsLogGroup"
    ]

    resources = var.cloudwatch_log_group_arns
  }

  statement {
    sid = "UpdateCloudWatchLogGroups"

    actions = [
      "logs:PutRetentionPolicy",
      "logs:DeleteRetentionPolicy",
      "logs:TagResource",
      "logs:UntagResource",
      "logs:TagLogGroup",
      "logs:UntagLogGroup"
    ]

    resources = var.cloudwatch_log_group_arns
  }

  statement {
    sid = "ManageCloudWatchAlarms"

    actions = [
      "cloudwatch:DescribeAlarms",
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:ListTagsForResource",
      "cloudwatch:TagResource",
      "cloudwatch:UntagResource"
    ]

    resources = var.cloudwatch_alarm_arns
  }

  statement {
    sid = "ManageCloudWatchDashboard"

    actions = [
      "cloudwatch:GetDashboard",
      "cloudwatch:PutDashboard"
    ]

    resources = [var.cloudwatch_dashboard_arn]
  }

  statement {
    sid = "ReadTerraformBackendBucket"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetBucketVersioning",
      "s3:GetEncryptionConfiguration",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetBucketOwnershipControls",
      "s3:GetBucketTagging",
      "s3:GetBucketAcl",
      "s3:GetBucketPolicy",
      "s3:GetBucketPolicyStatus",
      "s3:GetBucketCORS",
      "s3:GetBucketWebsite",
      "s3:GetBucketLogging",
      "s3:GetBucketRequestPayment",
      "s3:GetLifecycleConfiguration",
      "s3:GetReplicationConfiguration",
      "s3:GetAccelerateConfiguration",
      "s3:GetBucketObjectLockConfiguration"
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.terraform_state_bucket}"
    ]
  }

  statement {
    sid = "ReadLambdaEventSourceMappings"

    actions = [
      "lambda:GetEventSourceMapping",
      "lambda:ListEventSourceMappings"
    ]

    resources = ["*"]
  }

  statement {
    sid = "ReadLambdaEventSourceMappingTags"

    actions = [
      "lambda:ListTags"
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:lambda:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:event-source-mapping:*"
    ]
  }

}

resource "aws_iam_policy" "service_deployment" {
  name        = "${var.github_actions_role_name}-terraform-service-deployment"
  description = "Terraform AWS service deployment permissions for GitHub Actions"
  policy      = data.aws_iam_policy_document.service_deployment.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "service_deployment" {
  role       = var.github_actions_role_name
  policy_arn = aws_iam_policy.service_deployment.arn
}