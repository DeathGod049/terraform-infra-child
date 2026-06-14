variable "domain_name" { type = string; default = "ssp-opensearch" }
variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "private_subnets" { type = list(string) }

resource "aws_security_group" "opensearch" {
  name        = "${var.domain_name}-sg-${var.environment}"
  description = "Allow OpenSearch traffic from within VPC"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_iam_service_linked_role" "opensearch" {
  aws_service_name = "opensearchservice.amazonaws.com"
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
    subnet_ids         = [var.private_subnets[0]]
    security_group_ids = [aws_security_group.opensearch.id]
  }

  node_to_node_encryption {
    enabled = true
  }

  encrypt_at_rest {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = "admin"
      master_user_password = "anotherHardcodedPassword123!" # Store in SSM/SecretsManager in reality
    }
  }

  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "es:*"
        Principal = "*"
        Effect    = "Allow"
        Resource  = "arn:aws:es:*:*:domain/${var.domain_name}-${var.environment}/*"
      }
    ]
  })

  depends_on = [aws_iam_service_linked_role.opensearch]
}

output "opensearch_endpoint" {
  value = aws_opensearch_domain.main.endpoint
}
