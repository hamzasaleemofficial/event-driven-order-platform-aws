variable "lambda_function_name" {
  description = "Name of the Lambda function to monitor"
  type        = string
  default     = null
}

variable "sqs_dlq_name" {
  description = "Name of the SQS dead-letter queue to monitor"
  type        = string
  default     = null
}

variable "api_gateway_id" {
  description = "ID of the API Gateway HTTP API to monitor"
  type        = string
  default     = null
}

variable "api_gateway_stage" {
  description = "Stage name of the API Gateway HTTP API"
  type        = string
  default     = "$default"
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarm notifications"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to monitoring resources"
  type        = map(string)
  default     = {}
}