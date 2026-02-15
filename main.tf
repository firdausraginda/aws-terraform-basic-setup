module "vpc" {
  source = "./vpc"
}

module "subnet" {
  source         = "./subnet"
  default_vpc_id = module.vpc.default_vpc_id
}

module "sg" {
  source         = "./sg"
  default_vpc_id = module.vpc.default_vpc_id
}

module "ec2" {
  source               = "./ec2"
  iam_instance_profile = module.iam.airflow_ec2_instance_profile_name
}

module "ecr" {
  source = "./ecr"
}

module "s3" {
  source = "./s3"
}

module "iam" {
  source         = "./iam"
  s3_bucket_arn  = module.s3.bucket_arn
}

module "ecs" {
  source                     = "./ecs"
  ecr_repository_url         = module.ecr.repository_url
  ecs_task_execution_role_arn = module.iam.ecs_task_execution_role_arn
  ecs_task_role_arn           = module.iam.ecs_task_role_arn
  subnet_id                  = module.subnet.default_ap_southeast_1c_id
  vpc_id                     = module.vpc.default_vpc_id
  s3_bucket_name             = module.s3.bucket_name
}
