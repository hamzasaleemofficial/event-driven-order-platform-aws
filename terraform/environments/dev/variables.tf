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

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}