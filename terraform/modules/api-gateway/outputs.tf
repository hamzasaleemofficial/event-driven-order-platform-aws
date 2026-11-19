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