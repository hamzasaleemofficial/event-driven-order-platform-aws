output "table_id" {
  description = "ID of the DynamoDB table"
  value       = module.dynamodb_table.dynamodb_table_id
}

output "table_arn" {
  description = "ARN of the DynamoDB table"
  value       = module.dynamodb_table.dynamodb_table_arn
}

