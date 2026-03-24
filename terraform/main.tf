module "ecr" {
  source = "./modules/ecr"
}

module "eks" {
  source       = "./modules/eks"
  cluster_name = var.cluster_name
  aws_region   = var.aws_region
}

module "lambda" {
  source = "./modules/lambda"
}

module "apigateway" {
  source = "./modules/apigateway"

  private_subnet_ids     = module.eks.private_subnet_ids
  vpc_id                 = module.eks.vpc_id
  node_security_group_id = module.eks.node_security_group_id

  aws_region           = var.aws_region
}
