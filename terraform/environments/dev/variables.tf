variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "event-driven-order-platform"
}

variable "monitoring_alert_email" {
  description = "Email address that receives CloudWatch monitoring alerts"
  type        = string
  default     = null
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "github_oidc_role_name" {
  description = "Name of the IAM role assumed by GitHub Actions"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in owner/repository format"
  type        = string
}

variable "terraform_state_bucket" {
  description = "S3 bucket name for storing Terraform state"
  type        = string
}

variable "terraform_state_key" {
  description = "S3 key for the Terraform state file"
  type        = string
}

variable "api_lambda_function_name" {
  description = "Name of the API Lambda function"
  type        = string
}

variable "worker_lambda_function_name" {
  description = "Name of the Worker Lambda function"
  type        = string
}

variable "handler" {
  description = "The function within your code that Lambda calls to begin execution"
  type        = string
}

variable "runtime" {
  description = "The runtime environment for the Lambda function"
  type        = string
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}