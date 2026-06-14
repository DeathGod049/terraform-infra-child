variable "function_name" { type = string }
variable "environment" { type = string }
variable "container_image" { type = string }
variable "environment_variables" {
  type = map(string)
  default = {}
}
variable "execution_policy_arns" {
  description = "A list of IAM policy ARNs to attach to the Lambda execution role."
  type        = list(string)
  default     = []
}

# The CloudWatch Log Group and Subscription are now handled by the central module
# Lambda automatically creates a log group named /aws/lambda/<function_name>,
# so we pass that specific name to our module to manage the retention and subscription.
module "cloudwatch_logs" {
  source       = "../cloudwatch-logs"
  service_name = "../aws/lambda/${var.function_name}"
  environment  = var.environment
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.function_name}-${var.environment}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach custom policies passed in by the service
resource "aws_iam_role_policy_attachment" "custom" {
  for_each   = toset(var.execution_policy_arns)
  role       = aws_iam_role.lambda_exec.name
  policy_arn = each.value
}

resource "aws_lambda_function" "this" {
  function_name = "${var.function_name}-${var.environment}"
  role          = aws_iam_role.lambda_exec.arn
  package_type  = "Image"
  image_uri     = var.container_image == "placeholder" ? null : var.container_image

  environment {
    variables = var.environment_variables
  }

  # Ensure the log group exists and is subscribed BEFORE the lambda runs
  depends_on = [
    module.cloudwatch_logs
  ]
}

output "function_name" {
  value = aws_lambda_function.this.function_name
}
