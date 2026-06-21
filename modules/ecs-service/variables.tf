variable "aws_region" {
  description = "The AWS region where resources will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "The deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "container_image" {
  description = "The Docker image for the API gateway container"
  type        = string
  default     = "placeholder"
}
