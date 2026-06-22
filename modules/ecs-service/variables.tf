variable "service_name" { type = string }
variable "environment" { type = string }
variable "aws_region" { type = string }
variable "cluster_id" { type = string }
variable "vpc_id" { type = string }
variable "private_subnets" { type = list(string) }
variable "container_image" { type = string }
variable "container_port" { type = number }
variable "cloudmap_namespace_id" {
  description = "The ID of the Cloud Map private DNS namespace."
  type        = string
}
variable "task_policy_arns" {
  description = "A list of IAM policy ARNs to attach to the task role."
  type        = list(string)
  default     = []
}
variable "environment_variables" {
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}
