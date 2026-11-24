
data "aws_iam_policy_document" "worker_lambda_boundary" {
  statement {
    sid    = "AllowOrderQueueConsumption"
    effect = "Allow"

    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
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
      "dynamodb:GetItem",
      "dynamodb:UpdateItem"
    ]

    resources = [
      var.orders_table_arn
    ]
  }

  statement {
    sid    = "AllowOrderEventsPublishing"
    effect = "Allow"

    actions = [
      "sns:Publish"
    ]

    resources = [
      var.order_events_topic_arn
    ]
  }
  statement {
    sid    = "AllowKMSViaApplicationServices"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]

    resources = [
      var.kms_key_arn
    ]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"

      values = [
        "sqs.${data.aws_region.current.region}.amazonaws.com",
        "sns.${data.aws_region.current.region}.amazonaws.com",
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
      "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.worker_lambda_function_name}:*"
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

resource "aws_iam_policy" "worker_lambda_boundary" {
  name        = "${var.github_actions_role_name}-worker-boundary"
  description = "Maximum permissions allowed for the Worker Lambda execution role"

  policy = data.aws_iam_policy_document.worker_lambda_boundary.json

  tags = var.tags
}