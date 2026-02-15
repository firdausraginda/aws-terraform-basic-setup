output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.etl.arn
}

output "task_security_group_id" {
  value = aws_security_group.ecs_task.id
}

output "subnet_id" {
  value = var.subnet_id
}
