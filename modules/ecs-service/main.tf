variable "service_name" { type = string }
variable "environment" { type = string }
variable "cluster_id" { type = string }
variable "vpc_id" { type = string }
variable "private_subnets" { type = list(string) }
variable "container_image" { type = string }
variable "container_port" { type = number }
variable "environment_variables" {
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}
variable "task_policy_arns" {
  description = "A list of IAM policy ARNs to attach to the task role."
  type        = list(string)
  default     = []
}

# The CloudWatch Log Group and Subscription are now handled by the central module
module "cloudwatch_logs" {
  source       = "../cloudwatch-logs"
  service_name = var.service_name
  environment  = var.environment
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.service_name}-task-exec-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Attach custom policies passed in by the service
resource "aws_iam_role_policy_attachment" "custom" {
  for_each   = toset(var.task_policy_arns)
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = each.value
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.service_name}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn # Use the same role for the task role

  container_definitions = jsonencode([{
    name      = var.service_name
    image     = var.container_image == "placeholder" ? "nginx" : var.container_image
    essential = true
    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]
    environment = var.environment_variables
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = module.cloudwatch_logs.log_group_name
        awslogs-region        = "us-east-1"
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_security_group" "ecs_tasks" {
  name   = "${var.service_name}-sg-${var.environment}"
  vpc_id = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = var.container_port
    to_port     = var.container_port
    cidr_blocks = ["0.0.0.0/0"] # Should be restricted in prod to ALB SG
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "this" {
  name            = "${var.service_name}-${var.environment}"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets         = var.private_subnets
    security_groups = [aws_security_group.ecs_tasks.id]
  }
}

output "service_name" {
  value = aws_ecs_service.this.name
}
