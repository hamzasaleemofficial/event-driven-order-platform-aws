module "dynamodb_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "5.5.1"

  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "order_id"

  attributes = [
    {
      name = "order_id"
      type = "S"
    }
  ]

  point_in_time_recovery_enabled = true
  deletion_protection_enabled    = true

  server_side_encryption_enabled     = true
  server_side_encryption_kms_key_arn = var.kms_key_arn

  tags = var.tags
}