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
  source = "./ec2"
}
