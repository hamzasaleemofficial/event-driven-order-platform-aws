output "terraform_state_bucket_name" {
  description = "Name of the Terraform state bucket"
  value       = module.terraform_state.bucket_name
}

output "terraform_state_bucket_arn" {
  description = "ARN of the Terraform state bucket"
  value       = module.terraform_state.bucket_arn
}

output "kms_key_id" {
  description = "ID of the platform KMS key"
  value       = module.kms.key_id
}

output "kms_key_arn" {
  description = "ARN of the platform KMS key"
  value       = module.kms.key_arn
}

output "kms_alias_name" {
  description = "Alias of the platform KMS key"
  value       = module.kms.alias_name
}

output "orders_table_id" {
  description = "ID of the DynamoDB orders table"
  value       = module.orders_table.table_id
}

output "orders_table_arn" {
  description = "ARN of the DynamoDB orders table"
  value       = module.orders_table.table_arn
}

output "orders_queue_url" {
  description = "URL of the orders SQS queue"
  value       = module.orders_queue.queue_url
}

output "orders_queue_arn" {
  description = "ARN of the orders SQS queue"
  value       = module.orders_queue.queue_arn
}

output "orders_dlq_url" {
  description = "URL of the orders dead-letter queue"
  value       = module.orders_queue.dlq_url
}

output "orders_dlq_arn" {
  description = "ARN of the orders dead-letter queue"
  value       = module.orders_queue.dlq_arn
}

output "order_events_topic_arn" {
  description = "ARN of the SNS topic used for order-processing events"
  value       = module.order_events_topic.topic_arn
}

output "order_events_topic_name" {
  description = "Name of the SNS topic used for order-processing events"
  value       = module.order_events_topic.topic_name
}


output "api_endpoint" {
  description = "Base URL of the HTTP API"
  value       = module.api_gateway.api_endpoint
}

output "orders_endpoint" {
  description = "URL for submitting orders"
  value       = module.api_gateway.orders_endpoint
}

output "worker_lambda_name" {
  description = "Name of the Worker Lambda function"
  value       = module.worker_lambda.function_name
}

output "worker_lambda_arn" {
  description = "ARN of the Worker Lambda function"
  value       = module.worker_lambda.function_arn
}