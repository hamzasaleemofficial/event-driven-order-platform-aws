output "function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda.lambda_function_name
}

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda.lambda_function_arn
}

output "invoke_arn" {
  description = "Invoke ARN used by services such as API Gateway"
  value       = module.lambda.lambda_function_invoke_arn
}

output "role_arn" {
  description = "ARN of the Lambda execution IAM role"
  value       = module.lambda.lambda_role_arn
}