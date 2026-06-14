variable "service_name" {
  description = "The name of the service for which to create a log group."
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., dev, staging, prod)."
  type        = string
}

variable "log_retention_in_days" {
  description = "Number of days to retain logs."
  type        = number
  default     = 14
}

variable "log_forwarder_arn_ssm_param" {
  description = "The name of the SSM parameter holding the log forwarder Lambda ARN."
  type        = string
  default     = "/ssp/shared/log_forwarder_arn"
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.service_name}-${var.environment}"
  retention_in_days = var.log_retention_in_days
  tags = {
    Environment = var.environment
    Service     = var.service_name
  }
}

data "aws_ssm_parameter" "log_forwarder_arn" {
  name = var.log_forwarder_arn_ssm_param
}

resource "aws_cloudwatch_log_subscription_filter" "this" {
  name            = "${var.service_name}-${var.environment}-error-filter"
  log_group_name  = aws_cloudwatch_log_group.this.name
  filter_pattern  = "?ERROR ?WARNING ?CRITICAL ?Exception ?Traceback"
  destination_arn = data.aws_ssm_parameter.log_forwarder_arn.value

  # Depends on the Lambda permission being created in the log-forwarder service
  depends_on = [
    data.aws_ssm_parameter.log_forwarder_arn
  ]
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.this.name
}
