variable "github_actions_role_name" {
  description = "Name of the GitHub Actions IAM role"
  type        = string
}

variable "terraform_state_bucket" {
  description = "S3 bucket containing Terraform state"
  type        = string
}

variable "terraform_state_key" {
  description = "S3 object key for Terraform state"
  type        = string
}

variable "lambda_execution_role_arns" {
  description = "ARNs of Lambda execution roles managed by Terraform"
  type        = list(string)
}

variable "lambda_permissions_boundary_arns" {
  description = "Approved IAM permissions boundary ARNs for Lambda execution roles"
  type        = list(string)
}

variable "lambda_function_arns" {
  description = "ARNs of Lambda functions managed by the Terraform deployment role"
  type        = list(string)
}

variable "orders_table_arn" {
  description = "ARN of the DynamoDB orders table managed by Terraform"
  type        = string
}

variable "sqs_queue_arns" {
  description = "ARNs of SQS queues managed by the Terraform deployment role"
  type        = list(string)
}

variable "sns_topic_arns" {
  description = "ARNs of SNS topics managed by the Terraform deployment role"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "ARN of the KMS key managed by Terraform"
  type        = string
}

variable "api_gateway_arn" {
  description = "Management ARN of the API Gateway HTTP API"
  type        = string
}

variable "cloudwatch_log_group_arns" {
  description = "ARNs of CloudWatch log groups managed by Terraform"
  type        = list(string)
}

variable "cloudwatch_alarm_arns" {
  description = "ARNs of CloudWatch alarms managed by Terraform"
  type        = list(string)
}

variable "cloudwatch_dashboard_arn" {
  description = "ARN of the CloudWatch dashboard managed by Terraform"
  type        = string
}

variable "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role"
  type        = string
}

variable "tags" {
  description = "Tags applied to IAM resources"
  type        = map(string)
  default     = {}
}

