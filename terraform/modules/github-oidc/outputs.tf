output "role_name" {
  description = "Name of the GitHub Actions IAM role"
  value       = module.github_actions_role.name
}

output "role_arn" {
  description = "ARN of the GitHub Actions IAM role"
  value       = module.github_actions_role.arn
}