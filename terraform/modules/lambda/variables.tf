variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = ""
}

variable "handler" {
  description = "Lambda handler entry point"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.12"
}

variable "source_path" {
  description = "Path to the Lambda application source code"
  type        = string
}

variable "environment_variables" {
  description = "Environment variables passed to the Lambda function"
  type        = map(string)
  default     = {}
}

variable "policy_statements" {
  description = "IAM policy statements for the Lambda execution role"
  type        = any
  default     = {}
}

variable "event_source_mapping" {
  description = "Event source mappings for the Lambda function"
  type        = any
  default     = {}
}

variable "role_permissions_boundary" {
  description = "ARN of the IAM permissions boundary for the Lambda execution role"
  type        = string
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}