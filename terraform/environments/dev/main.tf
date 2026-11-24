module "terraform_state" {
  source = "../../modules/terraform-state"

  tags = var.tags
}

module "kms" {
  source = "../../modules/kms"

  description = "Encryption key for the Event-Driven Order Processing Platform (dev)"
  alias_name  = "event-driven-order-platform-dev"

  allow_cloudwatch_alarm_encryption = true

  tags = var.tags
}

module "orders_table" {
  source = "../../modules/dynamodb"

  table_name  = "event-driven-order-platform-dev-orders"
  kms_key_arn = module.kms.key_arn

  tags = var.tags
}

module "orders_queue" {
  source = "../../modules/sqs"

  queue_name  = "event-driven-order-platform-dev-orders"
  kms_key_arn = module.kms.key_arn

  tags = var.tags
}

module "order_events_topic" {
  source = "../../modules/sns"

  topic_name  = "event-driven-order-platform-dev-order-events"
  kms_key_arn = module.kms.key_arn

  tags = var.tags
}

module "api_lambda" {
  source = "../../modules/lambda"

  function_name = var.api_lambda_function_name
  description   = "API Lambda for accepting customer orders"

  role_permissions_boundary = module.iam_boundaries.api_lambda_boundary_arn

  handler = var.handler
  runtime = var.runtime

  source_path = "${path.root}/../../../application/api/package"

  environment_variables = {
    ORDERS_QUEUE_URL  = module.orders_queue.queue_url
    ORDERS_TABLE_NAME = module.orders_table.table_id
  }

  policy_statements = {
    send_orders_to_sqs = {
      effect = "Allow"

      actions = [
        "sqs:SendMessage"
      ]

      resources = [
        module.orders_queue.queue_arn
      ]
    }

    write_orders_to_dynamodb = {
      effect = "Allow"

      actions = [
        "dynamodb:PutItem"
      ]

      resources = [
        module.orders_table.table_arn
      ]
    }

    read_orders_from_dynamodb = {
      effect = "Allow"

      actions = [
        "dynamodb:GetItem"
      ]

      resources = [
        module.orders_table.table_arn
      ]
    }

    use_sqs_kms_key = {
      effect = "Allow"

      actions = [
        "kms:GenerateDataKey",
        "kms:Decrypt"
      ]

      resources = [
        module.kms.key_arn
      ]

      condition = [
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["sqs.eu-west-1.amazonaws.com"]
        }
      ]
    }

    use_dynamodb_kms_key = {
      effect = "Allow"

      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ]

      resources = [
        module.kms.key_arn
      ]

      condition = [
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["dynamodb.eu-west-1.amazonaws.com"]
        }
      ]
    }
  }

  tags = var.tags
}

module "api_gateway" {
  source = "../../modules/api-gateway"

  api_name = var.api_lambda_function_name

  lambda_invoke_arn    = module.api_lambda.invoke_arn
  lambda_function_name = module.api_lambda.function_name

  tags = var.tags
}

module "worker_lambda" {
  source = "../../modules/lambda"

  function_name = var.worker_lambda_function_name
  description   = "Worker Lambda for processing orders from SQS"

  role_permissions_boundary = module.iam_boundaries.worker_lambda_boundary_arn

  handler = var.handler
  runtime = var.runtime


  source_path = "${path.root}/../../../application/worker/package"

  environment_variables = {
    ORDERS_TABLE_NAME      = module.orders_table.table_id
    ORDER_EVENTS_TOPIC_ARN = module.order_events_topic.topic_arn
  }

  policy_statements = {
    consume_orders_from_sqs = {
      effect = "Allow"

      actions = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ]

      resources = [
        module.orders_queue.queue_arn
      ]
    }

    write_orders_to_dynamodb = {
      effect = "Allow"

      actions = [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:UpdateItem"
      ]

      resources = [
        module.orders_table.table_arn
      ]
    }

    publish_order_events = {
      effect = "Allow"

      actions = [
        "sns:Publish"
      ]

      resources = [
        module.order_events_topic.topic_arn
      ]
    }

    decrypt_sqs_messages = {
      effect = "Allow"

      actions = [
        "kms:Decrypt"
      ]

      resources = [
        module.kms.key_arn
      ]

      condition = [
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["sqs.eu-west-1.amazonaws.com"]
        }
      ]
    }

    use_sns_kms_key = {
      effect = "Allow"

      actions = [
        "kms:GenerateDataKey",
        "kms:Decrypt"
      ]

      resources = [
        module.kms.key_arn
      ]

      condition = [
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["sns.eu-west-1.amazonaws.com"]
        }
      ]
    }

    use_dynamodb_kms_key = {
      effect = "Allow"

      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ]

      resources = [
        module.kms.key_arn
      ]

      condition = [
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["dynamodb.eu-west-1.amazonaws.com"]
        }
      ]
    }
  }

  event_source_mapping = {
    orders_queue = {
      event_source_arn = module.orders_queue.queue_arn

      enabled    = true
      batch_size = 10

      function_response_types = [
        "ReportBatchItemFailures"
      ]
    }
  }

  tags = var.tags
}

module "api_lambda_monitoring" {
  source = "../../modules/monitoring"

  lambda_function_name = module.api_lambda.function_name
  alarm_sns_topic_arn  = module.monitoring_alerts_topic.topic_arn

  tags = var.tags
}

module "worker_lambda_monitoring" {
  source = "../../modules/monitoring"

  lambda_function_name = module.worker_lambda.function_name
  alarm_sns_topic_arn  = module.monitoring_alerts_topic.topic_arn

  tags = var.tags
}

module "orders_dlq_monitoring" {
  source = "../../modules/monitoring"

  sqs_dlq_name        = "${var.project_name}-${var.environment}-orders-dlq"
  alarm_sns_topic_arn = module.monitoring_alerts_topic.topic_arn

  tags = var.tags
}

module "api_gateway_monitoring" {
  source = "../../modules/monitoring"

  api_gateway_id      = module.api_gateway.api_id
  api_gateway_stage   = "$default"
  alarm_sns_topic_arn = module.monitoring_alerts_topic.topic_arn

  tags = var.tags
}

module "monitoring_alerts_topic" {
  source = "../../modules/sns"

  topic_name               = "${var.project_name}-${var.environment}-monitoring-alerts"
  kms_key_arn              = module.kms.key_arn
  allow_cloudwatch_publish = true

  tags = var.tags
}

# Email notifications for CloudWatch monitoring alerts
resource "aws_sns_topic_subscription" "monitoring_email" {
  count = var.monitoring_alert_email != null ? 1 : 0

  topic_arn = module.monitoring_alerts_topic.topic_arn
  protocol  = "email"
  endpoint  = var.monitoring_alert_email
}

# CloudWatch Dashboard
module "dashboard" {
  source = "../../modules/dashboard"

  dashboard_name = "${var.project_name}-${var.environment}-dashboard"
  aws_region     = "eu-west-1"

  api_lambda_name    = module.api_lambda.function_name
  worker_lambda_name = module.worker_lambda.function_name

  api_gateway_id    = module.api_gateway.api_id
  api_gateway_stage = "$default"

  orders_queue_name = "${var.project_name}-${var.environment}-orders"
  orders_dlq_name   = "${var.project_name}-${var.environment}-orders-dlq"
}

# GitHub Actions OIDC Authentication
module "github_oidc" {
  source = "../../modules/github-oidc"

  role_name = var.github_oidc_role_name

  github_repository = var.github_repository
  github_branch     = var.environment

  tags = var.tags
}

# GitHub Actions Terraform IAM Permissions
module "iam" {
  source = "../../modules/iam"

  github_actions_role_name = module.github_oidc.role_name

  terraform_state_bucket = var.terraform_state_bucket
  terraform_state_key    = var.terraform_state_key

  lambda_execution_role_arns = [
    module.api_lambda.role_arn,
    module.worker_lambda.role_arn
  ]

  lambda_permissions_boundary_arns = [
    module.iam_boundaries.api_lambda_boundary_arn,
    module.iam_boundaries.worker_lambda_boundary_arn
  ]

  lambda_function_arns = [
    module.api_lambda.function_arn,
    module.worker_lambda.function_arn
  ]

  orders_table_arn = module.orders_table.table_arn

  sqs_queue_arns = [
    module.orders_queue.queue_arn,
    module.orders_queue.dlq_arn
  ]

  sns_topic_arns = [
    module.order_events_topic.topic_arn,
    module.monitoring_alerts_topic.topic_arn
  ]

  kms_key_arn = module.kms.key_arn

  api_gateway_arn = module.api_gateway.api_arn

  cloudwatch_log_group_arns = [
    module.api_gateway.log_group_arn,
    module.api_lambda.log_group_arn,
    module.worker_lambda.log_group_arn
  ]

  cloudwatch_alarm_arns = [
    module.api_gateway_monitoring.api_gateway_5xx_alarm_arn,
    module.api_lambda_monitoring.alarm_arn,
    module.worker_lambda_monitoring.alarm_arn,
    module.orders_dlq_monitoring.sqs_dlq_alarm_arn
  ]

  cloudwatch_dashboard_arn = module.dashboard.dashboard_arn

  github_actions_role_arn = module.github_oidc.role_arn

  tags = var.tags
}


module "iam_boundaries" {
  source = "../../modules/iam-boundaries"

  github_actions_role_name = module.github_oidc.role_name

  orders_queue_arn       = module.orders_queue.queue_arn
  orders_table_arn       = module.orders_table.table_arn
  order_events_topic_arn = module.order_events_topic.topic_arn
  kms_key_arn            = module.kms.key_arn

  api_lambda_function_name    = var.api_lambda_function_name
  worker_lambda_function_name = var.worker_lambda_function_name

  tags = var.tags
}