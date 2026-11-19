variable "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  type        = string
}

variable "aws_region" {
  description = "AWS region containing the monitored resources"
  type        = string
}

variable "api_lambda_name" {
  description = "Name of the API Lambda function"
  type        = string
}

variable "worker_lambda_name" {
  description = "Name of the Worker Lambda function"
  type        = string
}

variable "api_gateway_id" {
  description = "ID of the API Gateway HTTP API"
  type        = string
}

variable "api_gateway_stage" {
  description = "API Gateway stage name"
  type        = string
  default     = "$default"
}

variable "orders_queue_name" {
  description = "Name of the main SQS orders queue"
  type        = string
}

variable "orders_dlq_name" {
  description = "Name of the SQS dead-letter queue"
  type        = string
}