variable "cluster_name" { type = string; default = "ssp-redis" }
variable "environment" { type = string }
variable "private_subnets" { type = list(string) }
variable "vpc_id" { type = string }

resource "aws_security_group" "redis" {
  name        = "${var.cluster_name}-sg-${var.environment}"
  description = "Allow Redis traffic from within the VPC"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 6379
    to_port     = 6379
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.cluster_name}-subnet-group-${var.environment}"
  subnet_ids = var.private_subnets
}

resource "aws_elasticache_cluster" "main" {
  cluster_id           = "${var.cluster_name}-${var.environment}"
  engine               = "redis"
  node_type            = "cache.t2.micro" # Smallest, most cost-effective node
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [aws_security_group.redis.id]
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.main.cache_nodes[0].address
}
