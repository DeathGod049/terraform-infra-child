resource "aws_security_group" "rds" {
  name        = "ssp-rds-sg-${var.environment}"
  description = "Allow Postgres traffic from within the VPC"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 5432
    to_port     = 5432
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "ssp-rds-subnet-group-${var.environment}"
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
  name = "ssp/rds/credentials-${var.environment}"
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.password.result
    dbname   = var.db_name
  })
}

resource "aws_db_instance" "main" {
  identifier             = "ssp-postgres-${var.environment}"
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  db_name                = var.db_name
  username               = var.db_username
  password               = random_password.password.result
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true
}

output "rds_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "db_credentials_secret_arn" {
  value = aws_secretsmanager_secret.db_credentials.arn
}

output "db_password" {
  value = random_password.password.result
  sensitive = true
}
