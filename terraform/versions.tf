terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "fcg-terraform-state"
    key            = "fcg/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "fcg-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region
}
