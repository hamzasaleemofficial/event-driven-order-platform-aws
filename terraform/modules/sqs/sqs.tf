module "orders_queue" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "5.2.2"

  name       = var.queue_name
  fifo_queue = false

  # Main orders queue
  message_retention_seconds  = 345600 # 4 days
  visibility_timeout_seconds = 180
  receive_wait_time_seconds  = 20

  # Encryption using the existing customer-managed KMS key
  kms_master_key_id                 = var.kms_key_arn
  kms_data_key_reuse_period_seconds = 300

  # Dead-letter queue
  create_dlq                     = true
  dlq_name                       = "${var.queue_name}-dlq"
  dlq_message_retention_seconds  = 1209600 # 14 days
  dlq_visibility_timeout_seconds = 180
  dlq_receive_wait_time_seconds  = 0

  dlq_kms_master_key_id                 = var.kms_key_arn
  dlq_kms_data_key_reuse_period_seconds = 300

  # Move a message to the DLQ after repeated failed receives
  redrive_policy = {
    maxReceiveCount = 5
  }

  # Only this orders queue may use the DLQ as its redrive target
  create_dlq_redrive_allow_policy = true

  tags = var.tags
}