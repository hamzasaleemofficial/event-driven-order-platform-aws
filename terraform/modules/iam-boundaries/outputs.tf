output "api_lambda_boundary_arn" {
  description = "ARN of the API Lambda permissions boundary"
  value       = aws_iam_policy.api_lambda_boundary.arn
}

output "worker_lambda_boundary_arn" {
  description = "ARN of the Worker Lambda permissions boundary"
  value       = aws_iam_policy.worker_lambda_boundary.arn
}