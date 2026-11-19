variable "description" {
  description = "Description of the KMS key"
  type        = string
}

variable "alias_name" {
  description = "KMS alias name without the alias/ prefix"
  type        = string
}

variable "allow_cloudwatch_alarm_encryption" {
  description = "Allow CloudWatch alarms to use the KMS key for encrypted SNS notifications"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to the KMS resources"
  type        = map(string)
  default     = {}
}