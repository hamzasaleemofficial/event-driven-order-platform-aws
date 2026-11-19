output "queue_url" {
  description = "URL of the orders SQS queue"
  value       = module.orders_queue.queue_url
}

output "queue_arn" {
  description = "ARN of the orders SQS queue"
  value       = module.orders_queue.queue_arn
}

output "queue_name" {
  description = "Name of the orders SQS queue"
  value       = module.orders_queue.queue_name
}

output "dlq_url" {
  description = "URL of the orders dead-letter queue"
  value       = module.orders_queue.dead_letter_queue_url
}

output "dlq_arn" {
  description = "ARN of the orders dead-letter queue"
  value       = module.orders_queue.dead_letter_queue_arn
}

output "dlq_name" {
  description = "Name of the orders dead-letter queue"
  value       = module.orders_queue.dead_letter_queue_name
}