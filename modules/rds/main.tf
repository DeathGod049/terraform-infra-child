variable "db_name" { type = string; default = "ssp_db" }
variable "environment" { type = string }
variable "private_subnets" { type = list(string) }
variable "vpc_id" { type = string }

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

resource "aws_db_instance" "main" {
  identifier             = "ssp-postgres-${var.environment}"
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro" # Cost-effective instance type
  db_name                = var.db_name
  username               = "postgres"
  password               = "anotherHardcodedPassword123!" # Again, use Secrets Manager in reality
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true
}

output "rds_endpoint" {
  value = aws_db_instance.main.endpoint
}
