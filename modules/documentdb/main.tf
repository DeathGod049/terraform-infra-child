resource "aws_security_group" "docdb" {
  name        = "${var.cluster_name}-sg-${var.environment}"
  description = "Allow DocumentDB traffic from within the VPC"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 27017
    to_port     = 27017
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_docdb_subnet_group" "main" {
  name       = "${var.cluster_name}-subnet-group-${var.environment}"
  subnet_ids = var.private_subnets
}

# Generate a random, secure password
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&()*+,-.:;<=>?[]^_{|}~"
}

# Store the credentials in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_credentials" {
  name = "ssp/docdb/credentials-${var.environment}"
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.password.result
  })
}

resource "aws_docdb_cluster" "main" {
  cluster_identifier      = "${var.cluster_name}-${var.environment}"
  engine                  = "docdb"
  master_username         = var.db_username
  master_password         = random_password.password.result
  db_subnet_group_name    = aws_docdb_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.docdb.id]
  skip_final_snapshot     = true
}

resource "aws_docdb_cluster_instance" "main" {
  count              = 1
  identifier         = "${var.cluster_name}-instance-${var.environment}"
  cluster_identifier = aws_docdb_cluster.main.id
  instance_class     = "db.t3.medium"
}

output "documentdb_endpoint" {
  value = aws_docdb_cluster.main.endpoint
}

output "documentdb_connection_string" {
  value = "mongodb://${var.db_username}:${random_password.password.result}@${aws_docdb_cluster.main.endpoint}:27017/?tls=true&tlsCAFile=global-bundle.pem&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
}

output "db_credentials_secret_arn" {
  value = aws_secretsmanager_secret.db_credentials.arn
}
