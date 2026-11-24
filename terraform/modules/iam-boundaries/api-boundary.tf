
data "aws_iam_policy_document" "api_lambda_boundary" {
  statement {
    sid    = "AllowOrderQueuePublishing"
    effect = "Allow"

    actions = [
      "sqs:SendMessage"
    ]

    resources = [
      var.orders_queue_arn
    ]
  }

  statement {
    sid    = "AllowOrdersTableAccess"
    effect = "Allow"

    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem"
    ]

    resources = [
      var.orders_table_arn
    ]
  }
  statement {
    sid    = "AllowKMSViaApplicationServices"
    effect = "Allow"

    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]

    resources = [
      var.kms_key_arn
    ]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"

      values = [
        "sqs.${data.aws_region.current.region}.amazonaws.com",
        "dynamodb.${data.aws_region.current.region}.amazonaws.com"
      ]
    }
  }
  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.api_lambda_function_name}:*"
    ]
  }

  statement {
    sid    = "AllowXRayTracing"
    effect = "Allow"

    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "api_lambda_boundary" {
  name        = "${var.github_actions_role_name}-api-boundary"
  description = "Maximum permissions allowed for the API Lambda execution role"

  policy = data.aws_iam_policy_document.api_lambda_boundary.json

  tags = var.tags
}