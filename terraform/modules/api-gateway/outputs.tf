output "api_id" {
  description = "ID of the HTTP API"
  value       = module.api_gateway.api_id
}

output "api_endpoint" {
  description = "Base URL of the HTTP API"
  value       = module.api_gateway.api_endpoint
}

output "orders_endpoint" {
  description = "URL for creating orders"
  value       = "${module.api_gateway.api_endpoint}/orders"
}

output "api_arn" {
  description = "Management ARN of the API Gateway HTTP API"
  value       = "arn:${data.aws_partition.current.partition}:apigateway:${data.aws_region.current.region}::/apis/${module.api_gateway.api_id}"
}

output "log_group_arn" {
  description = "ARN of the API Gateway access log group"
  value       = module.api_gateway.stage_access_logs_cloudwatch_log_group_arn
}