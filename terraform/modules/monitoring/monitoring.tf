module "lambda_error_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "~> 3.0"

  count = var.lambda_function_name != null ? 1 : 0

  alarm_name          = "${var.lambda_function_name}-errors"
  alarm_description   = "Lambda errors: one or more failures within five minutes"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  evaluation_periods = 1
  threshold          = 1
  period             = 300

  namespace   = "AWS/Lambda"
  metric_name = "Errors"
  statistic   = "Sum"

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  treat_missing_data = "notBreaching"

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = var.tags
}

module "sqs_dlq_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "~> 3.0"

  count = var.sqs_dlq_name != null ? 1 : 0

  alarm_name          = "${var.sqs_dlq_name}-messages-visible"
  alarm_description   = "SQS DLQ contains one or more messages"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  evaluation_periods = 1
  threshold          = 1
  period             = 300

  namespace   = "AWS/SQS"
  metric_name = "ApproximateNumberOfMessagesVisible"
  statistic   = "Maximum"

  dimensions = {
    QueueName = var.sqs_dlq_name
  }

  treat_missing_data = "notBreaching"

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = var.tags
}

module "api_gateway_5xx_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "~> 3.0"

  count = var.api_gateway_id != null ? 1 : 0

  alarm_name          = "${var.api_gateway_id}-${var.api_gateway_stage}-5xx"
  alarm_description   = "API Gateway HTTP API: one or more 5xx responses within five minutes"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  evaluation_periods = 1
  threshold          = 1
  period             = 300

  namespace   = "AWS/ApiGateway"
  metric_name = "5xx"
  statistic   = "Sum"

  dimensions = {
    ApiId = var.api_gateway_id
    Stage = var.api_gateway_stage
  }

  treat_missing_data = "notBreaching"

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = var.tags
}