variable "private_subnet_ids" {
  description = "Private subnet IDs from the EKS VPC (used by VPC Link)"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID where EKS cluster runs"
  type        = string
}

variable "node_security_group_id" {
  description = "Security group ID of EKS worker nodes"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}
