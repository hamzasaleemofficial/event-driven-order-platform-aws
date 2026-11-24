variable "github_actions_role_name" {
  description = "GitHub Actions role name used as the boundary policy naming prefix"
  type        = string
}

variable "orders_queue_arn" {
  description = "ARN of the orders SQS queue"
  type        = string
}

variable "orders_table_arn" {
  description = "ARN of the orders DynamoDB table"
  type        = string
}

variable "order_events_topic_arn" {
  description = "ARN of the order events SNS topic"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the application KMS key"
  type        = string
}

variable "api_lambda_function_name" {
  description = "Name of the API Lambda function"
  type        = string
}

variable "worker_lambda_function_name" {
  description = "Name of the Worker Lambda function"
  type        = string
}

variable "tags" {
  description = "Tags applied to IAM boundary policies"
  type        = map(string)
  default     = {}
}