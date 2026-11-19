variable "role_name" {
  description = "Name of the IAM role assumed by GitHub Actions"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in owner/repository format"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch allowed to assume the IAM role"
  type        = string
}

variable "tags" {
  description = "Tags applied to AWS resources"
  type        = map(string)
  default     = {}
}