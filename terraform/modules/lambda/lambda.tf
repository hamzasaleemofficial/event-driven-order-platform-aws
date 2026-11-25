module "lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.1.0"

  function_name = var.function_name
  description   = var.description

  handler = var.handler
  runtime = var.runtime

  source_path = [
    {
      path = var.source_path

      patterns = [
        "!.*\\.pyc$",
        "!.*\\.pyo$",
        "!.*__pycache__.*"
      ]
    }
  ]

  memory_size = 256
  timeout     = 30

  environment_variables = var.environment_variables

  create_role               = true
  role_permissions_boundary = var.role_permissions_boundary

  recreate_missing_package     = false
  trigger_on_package_timestamp = false

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