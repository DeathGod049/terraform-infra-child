output "task_role_name" {
  description = "The name of the IAM role used by the ECS task"
  value       = aws_iam_role.ecs_task_execution_role.name
}

output "task_role_arn" {
  description = "The ARN of the IAM role used by the ECS task"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "service_name" {
  description = "The name of the ECS service created"
  value       = aws_ecs_service.this.name
}
