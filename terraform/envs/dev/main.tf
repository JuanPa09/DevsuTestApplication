module "vpc" {
  source = "../../modules/vpc"

  name_prefix = local.name_prefix
  aws_region  = var.aws_region
}

module "eks" {
  source = "../../modules/eks"

  name_prefix = local.name_prefix
  aws_region  = var.aws_region

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids
}

module "ecr" {
  source = "../../modules/ecr"

  name_prefix = local.name_prefix
}