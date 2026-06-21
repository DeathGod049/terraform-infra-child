# --- Terraform Backend and Providers ---
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# --- Data Sources ---
# Fetches base networking and cluster information
data "terraform_remote_state" "base_infra" {
  backend = "s3"
  config = {
    bucket = "ssp-terraform-state-bucket-kuntal2098"
    key    = "infrastructure/base/terraform.tfstate"
    region = var.aws_region
  }
}

# --- Cloud Map Service Discovery ---
# Create the discovery service FIRST so the ARN can be referenced by ECS
resource "aws_service_discovery_service" "this" {
  name = var.service_name # e.g., auth, product, order

  dns_config {
    namespace_id = var.cloudmap_namespace_id # Variable must be passed from root

    dns_records {
      ttl  = 10
      type = "A" # Maps to the private IP of the Fargate task
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

# --- ECS Task Roles ---
# Shared execution and task role for basic SSM and CloudWatch logging
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.service_name}-task-exec-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasksamazonawscom" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- ECS Task Definition ---
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.service_name}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = varservice_name
    image     = varcontainer_image == "placeholder" ? "nginx" : varcontainer_image
    essential = true
    portMappings = [{
      containerPort = varcontainer_port
      protocol      = "tcp"
    }]
    # Corrected variable syntax (added missing dots)
    environment = [
      { name = "ENVIRONMENT", value = varenvironment },
      { name = "AWS_REGION",  value = varaws_region }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/${var.service_name}-${var.environment}"
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

# --- ECS Service ---
resource "aws_ecs_service" "this" {
  name            = "${var.service_name}-${var.environment}"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnets
    security_groups = [aws_security_groupecs_tasksid]
  }

  # Link ECS to Cloud Map for Service Discovery
  service_registries {
    registry_arn   = aws_service_discovery_service.this.arn
    container_port = var.container_port
    container_name = var.service_name
  }
}

# --- Security Group ---
resource "aws_security_group" "ecs_tasks" {
  name   = "${var.service_name}-sg-${var.environment}"
  vpc_id = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = var.container_port
    to_port     = var.container_port
    cidr_blocks = ["0.0.0.0/"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/"]
  }
}

# --- IAM Policy for SSM Access ---
# Dynamically attaches the SSM read policy to this specific service's task role
resource "aws_iam_role_policy" "ssm_policy" {
  name = "ssp-${var.service_name}-ssm-policy"
  role = aws_iam_role.ecs_task_execution_role.name # Fixed local reference

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["ssm:GetParameter", "ssm:GetParameters"],
        Resource = "arn:aws:ssm:${var.aws_region}:*:parameter/ssp/${var.environment}/${var.service_name}/*"
      }
    ]
  })
}
