# --- Terraform Backend and Providers ---
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # Dynamic backend initialized via Jenkins backend.conf
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

# --- Data Sources ---
data "terraform_remote_state" "base_infra" {
  backend = "s3"
  config = {
    bucket = "ssp-terraform-state-bucket-kuntal2098"
    key    = "infrastructure/base/terraform.tfstate"
    region = var.aws_region
  }
}

# --- ECR Repository ---
module "ecr" {
  source          = "git::https://github.com"
  repository_name = "ssp-api-gateway"
  environment     = var.environment
}

# --- ECS Service ---
module "ecs_service" {
  source          = "git::https://github.com"
  service_name    = "ssp-api-gateway"
  environment     = var.environment
  cluster_id      = data.terraform_remote_state.base_infra.outputs.ecs_cluster_id
  vpc_id          = data.terraform_remote_state.base_infra.outputs.vpc_id
  private_subnets = data.terraform_remote_state.base_infra.outputs.private_subnets
  container_image = var.container_image
  container_port  = 80

  # Environment variables for SSM discovery
  environment_variables = [
    { name = "ENVIRONMENT", value = varenvironment },
    { name = "AWS_REGION",  value = varaws_region }
  ]
}

# --- IAM Policy for SSM Access ---
resource "aws_iam_role_policy" "ssm_policy" {
  name = "ssp-api-gateway-ssm-policy"
  role = module.ecs_service.task_role_name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ],
        Resource = "arn:aws:ssm:${var.aws_region}:*:parameter/ssp/${var.environment}/api-gateway/*"
      }
    ]
  })
}
