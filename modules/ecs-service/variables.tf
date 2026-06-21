variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type = string
}

variable "service_name" {
  type = string
}

variable "cluster_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "container_image" {
  type    = string
  default = "placeholder"
}

variable "container_port" {
  type    = number
  default = 80
}

variable "cloudmap_namespace_id" {
  description = "The ID of the Cloud Map private DNS namespace"
  type        = string
}
