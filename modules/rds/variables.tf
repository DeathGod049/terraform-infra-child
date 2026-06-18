variable "db_name" {
  description = "The name of the database to create."
  type        = string
}

variable "db_username" {
  description = "The username for the master database user."
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., dev, staging, prod)."
  type        = string
}

variable "private_subnets" {
  description = "A list of private subnet IDs to deploy the database into."
  type        = list(string)
}

variable "vpc_id" {
  description = "The ID of the VPC where the database will be deployed."
  type        = string
}
