variable "queue_name" {
  description = "Name of the orders SQS queue"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the customer-managed KMS key used by both queues"
  type        = string
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}