# variables.tf (Ensure these are defined)
variable "domain_name" { type = string; default = "ssp-opensearch" }
variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "private_subnets" { type = list(string) }

# 1. Generate a secure random password
# OpenSearch passwords must be between 8 and 128 characters
resource "random_password" "opensearch_master" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+{}<>:?" # Avoid characters that might break some shells
}

# 2. Store the generated password in AWS SSM Parameter Store as a SecureString
resource "aws_ssm_parameter" "opensearch_password" {
  name        = "/ssp/${var.environment}/opensearch/master_password"
  description = "Master password for OpenSearch ${var.environment} domain"
  type        = "SecureString"
  value       = random_password.opensearch_master.result
}

resource "aws_security_group" "opensearch" {
  name        = "${var.domain_name}-sg-${var.environment}"
  description = "Allow OpenSearch traffic from within VPC"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/"]
  }
}

resource "aws_iam_service_linked_role" "opensearch" {
  aws_service_name = "://amazonaws.com"
}

resource "aws_opensearch_domain" "main" {
  domain_name    = "${var.domain_name}-${var.environment}"
  engine_version = "OpenSearch_2.11"

  cluster_config {
    instance_type          = "t3.small.search"
    instance_count         = 1
    zone_awareness_enabled = false
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
    volume_type = "gp3"
  }

  vpc_options {
    subnet_ids         = [varprivate_subnets[]]
    security_group_ids = [aws_security_groupopensearchid]
  }

  node_to_node_encryption { enabled = true }
  encrypt_at_rest         { enabled = true }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = "admin"
      # 3. Use the randomly generated password
      master_user_password = random_password.opensearch_master.result
    }
  }

  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "es:*"
        Principal = "*"
        Effect    = "Allow"
        Resource  = "arn:aws:es:*:*:domain/${vardomain_name}-${varenvironment}/*"
      }
    ]
  })

  depends_on = [aws_iam_service_linked_roleopensearch]
}

output "opensearch_endpoint" {
  value = aws_opensearch_domain.main.endpoint
}
