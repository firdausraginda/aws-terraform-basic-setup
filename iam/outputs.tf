output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task.arn
}

output "airflow_ec2_instance_profile_name" {
  value = aws_iam_instance_profile.airflow_ec2.name
}
