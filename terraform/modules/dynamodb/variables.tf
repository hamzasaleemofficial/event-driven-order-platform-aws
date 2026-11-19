variable "table_name" {
  description = "Name of the DynamoDB orders table"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the customer-managed KMS key"
  type        = string
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}