module "lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.1.0"

  function_name = var.function_name
  description   = var.description

  handler = var.handler
  runtime = var.runtime

  source_path = var.source_path

  memory_size = 256
  timeout     = 30

  environment_variables = var.environment_variables

  create_role = true

  attach_policy_statements = true
  policy_statements        = var.policy_statements

  attach_cloudwatch_logs_policy     = true
  cloudwatch_logs_retention_in_days = 14

  # Structured JSON logging
  logging_log_format            = "JSON"
  logging_application_log_level = "INFO"
  logging_system_log_level      = "WARN"

  # AWS X-Ray distributed tracing
  tracing_mode          = "Active"
  attach_tracing_policy = true

  event_source_mapping = var.event_source_mapping

  tags = var.tags
}