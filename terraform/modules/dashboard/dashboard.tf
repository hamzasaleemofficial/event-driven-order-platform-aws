resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = var.dashboard_name

  dashboard_body = jsonencode({
    start          = "-PT3H"
    periodOverride = "auto"

    widgets = [
      # API Lambda: Invocations and Errors
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "API Lambda - Invocations and Errors"
          region = var.aws_region
          period = 300
          stat   = "Sum"

          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", var.api_lambda_name],
            [".", "Errors", ".", "."]
          ]

          view    = "timeSeries"
          stacked = false
        }
      },

      # API Lambda: Duration
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "API Lambda - Average Duration"
          region = var.aws_region
          period = 300
          stat   = "Average"

          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", var.api_lambda_name]
          ]

          view    = "timeSeries"
          stacked = false
          yAxis = {
            left = {
              label = "Milliseconds"
              min   = 0
            }
          }
        }
      },

      # Worker Lambda: Invocations and Errors
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "Worker Lambda - Invocations and Errors"
          region = var.aws_region
          period = 300
          stat   = "Sum"

          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", var.worker_lambda_name],
            [".", "Errors", ".", "."]
          ]

          view    = "timeSeries"
          stacked = false
        }
      },

      # Worker Lambda: Duration
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "Worker Lambda - Average Duration"
          region = var.aws_region
          period = 300
          stat   = "Average"

          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", var.worker_lambda_name]
          ]

          view    = "timeSeries"
          stacked = false
          yAxis = {
            left = {
              label = "Milliseconds"
              min   = 0
            }
          }
        }
      },

      # API Gateway: Requests and 5xx Errors
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          title  = "API Gateway - Requests and 5xx Errors"
          region = var.aws_region
          period = 300
          stat   = "Sum"

          metrics = [
            ["AWS/ApiGateway", "Count", "ApiId", var.api_gateway_id, "Stage", var.api_gateway_stage],
            [".", "5xx", ".", ".", ".", "."]
          ]

          view    = "timeSeries"
          stacked = false
        }
      },

      # SQS Orders Queue: Visible Messages
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6

        properties = {
          title  = "SQS Orders Queue - Visible Messages"
          region = var.aws_region
          period = 300
          stat   = "Maximum"

          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", var.orders_queue_name]
          ]

          view    = "timeSeries"
          stacked = false
        }
      },

      # SQS DLQ: Visible Messages
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 12
        height = 6

        properties = {
          title  = "SQS Dead-Letter Queue - Visible Messages"
          region = var.aws_region
          period = 300
          stat   = "Maximum"

          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", var.orders_dlq_name]
          ]

          view    = "timeSeries"
          stacked = false
        }
      }
    ]
  })
}