output "task_role_name" {
  description = "The name of the IAM role used by the ECS task"
  value       = aws_iam_role.ecs_task_execution_role.name
}

output "task_role_arn" {
  description = "The ARN of the IAM role used by the ECS task"
  value       = aws_iam_role.ecs_task_execution_role.arn
}
