module "api_gateway" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "~> 6.0"

  name          = var.api_name
  protocol_type = "HTTP"

  create_domain_name = false

  stage_default_route_settings = {
    throttling_burst_limit = 5
    throttling_rate_limit  = 2
  }

  routes = {
    "POST /orders" = {
      integration = {
        uri                    = var.lambda_invoke_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 30000
      }
    }

    "GET /orders/{order_id}" = {
      integration = {
        uri                    = var.lambda_invoke_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 30000
      }
    }
  }

  tags = var.tags
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${module.api_gateway.api_execution_arn}/*/*/orders*"
}