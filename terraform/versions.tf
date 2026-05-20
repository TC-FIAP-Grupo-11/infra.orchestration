terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~> 1.15"
    }
    ec = {
      source  = "elastic/ec"
      version = "~> 0.10"
    }
  }

  # bucket passado via -backend-config no deploy.sh (nome inclui account ID para unicidade global)
  backend "s3" {
    key            = "fcg/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "fcg-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region
}

provider "mongodbatlas" {
  public_key  = var.atlas_public_key
  private_key = var.atlas_private_key
}

provider "ec" {
  apikey = var.elastic_cloud_api_key
}

# Requer que o cluster EKS já exista (aplique module.eks antes)
data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    command     = "aws"
  }
}
