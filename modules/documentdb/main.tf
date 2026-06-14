variable "cluster_name" { type = string; default = "ssp-docdb" }
variable "environment" { type = string }
variable "private_subnets" { type = list(string) }
variable "vpc_id" { type = string }

resource "aws_security_group" "docdb" {
  name        = "${var.cluster_name}-sg-${var.environment}"
  description = "Allow DocumentDB traffic from within the VPC"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 27017
    to_port     = 27017
    # In a real setup, you'd restrict this to the security groups of your services
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_docdb_subnet_group" "main" {
  name       = "${var.cluster_name}-subnet-group-${var.environment}"
  subnet_ids = var.private_subnets
}

resource "aws_docdb_cluster" "main" {
  cluster_identifier      = "${var.cluster_name}-${var.environment}"
  engine                  = "docdb"
  master_username         = "sspadmin"
  # The password should be managed via AWS Secrets Manager, not hardcoded
  master_password         = "someHardcodedPassword123!"
  db_subnet_group_name    = aws_docdb_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.docdb.id]
  skip_final_snapshot     = true
}

resource "aws_docdb_cluster_instance" "main" {
  count              = 1 # Single instance for cost savings
  identifier         = "${var.cluster_name}-instance-${var.environment}"
  cluster_identifier = aws_docdb_cluster.main.id
  instance_class     = "db.t3.medium" # Smallest available instance type
}

output "documentdb_endpoint" {
  value = aws_docdb_cluster.main.endpoint
}

output "documentdb_connection_string" {
  # Note: This includes the hardcoded password. A better approach is to store this in Secrets Manager.
  value = "mongodb://${aws_docdb_cluster.main.master_username}:${aws_docdb_cluster.main.master_password}@${aws_docdb_cluster.main.endpoint}:27017/?tls=true&tlsCAFile=global-bundle.pem&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
}
