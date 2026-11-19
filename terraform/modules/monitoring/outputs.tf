output "alarm_arn" {
  description = "ARN of the Lambda error alarm, if enabled"
  value       = var.lambda_function_name != null ? module.lambda_error_alarm[0].cloudwatch_metric_alarm_arn : null
}

output "alarm_name" {
  description = "Name of the Lambda error alarm, if enabled"
  value       = var.lambda_function_name != null ? module.lambda_error_alarm[0].cloudwatch_metric_alarm_id : null
}

output "sqs_dlq_alarm_arn" {
  description = "ARN of the SQS DLQ alarm, if enabled"
  value       = var.sqs_dlq_name != null ? module.sqs_dlq_alarm[0].cloudwatch_metric_alarm_arn : null
}

output "sqs_dlq_alarm_name" {
  description = "Name of the SQS DLQ alarm, if enabled"
  value       = var.sqs_dlq_name != null ? module.sqs_dlq_alarm[0].cloudwatch_metric_alarm_id : null
}

output "api_gateway_5xx_alarm_arn" {
  description = "ARN of the API Gateway 5xx alarm, if enabled"
  value       = var.api_gateway_id != null ? module.api_gateway_5xx_alarm[0].cloudwatch_metric_alarm_arn : null
}

output "api_gateway_5xx_alarm_name" {
  description = "Name of the API Gateway 5xx alarm, if enabled"
  value       = var.api_gateway_id != null ? module.api_gateway_5xx_alarm[0].cloudwatch_metric_alarm_id : null
}