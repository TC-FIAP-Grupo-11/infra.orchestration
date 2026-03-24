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

  aws_region = var.aws_region
}

resource "random_password" "sa" {
  length           = 16
  special          = true
  override_special = "!@#$"
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}

module "cognito" {
  source = "./modules/cognito"
}

module "k8s_secrets" {
  source = "./modules/k8s-secrets"

  sa_password           = random_password.sa.result
  cognito_authority     = module.cognito.authority
  cognito_user_pool_id  = module.cognito.user_pool_id
  cognito_client_id     = module.cognito.client_id
  cognito_client_secret = module.cognito.client_secret
  admin_email           = var.admin_email
  admin_password        = var.admin_password
}
