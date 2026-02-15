output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_task_security_group_id" {
  value = module.ecs.task_security_group_id
}

output "ecs_subnet_id" {
  value = module.ecs.subnet_id
}

output "s3_bucket_name" {
  value = module.s3.bucket_name
}
