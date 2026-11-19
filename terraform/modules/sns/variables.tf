variable "topic_name" {
  description = "Name of the SNS topic"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the existing customer-managed KMS key"
  type        = string
}

variable "allow_cloudwatch_publish" {
  description = "Allow CloudWatch alarms in this AWS account to publish to the SNS topic"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}