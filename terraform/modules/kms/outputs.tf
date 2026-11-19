output "key_id" {
  description = "ID of the KMS key"
  value       = module.kms.key_id
}

output "key_arn" {
  description = "ARN of the KMS key"
  value       = module.kms.key_arn
}

output "alias_name" {
  description = "Full KMS alias name"
  value       = "alias/${var.alias_name}"
}