variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "fcg-cluster"
}

variable "admin_email" {
  description = "Admin user email for seeding"
  type        = string
  default = "admin@fcg.com"
}

variable "admin_password" {
  description = "Admin user password for seeding"
  type        = string
  sensitive   = true
}

variable "new_relic_license_key" {
  description = "New Relic ingest license key"
  type        = string
  sensitive   = true
}

variable "rabbitmq_password" {
  description = "RabbitMQ password injected into all service secrets"
  type        = string
  sensitive   = true
}

variable "atlas_org_id" {
  description = "MongoDB Atlas organization ID"
  type        = string
}

variable "atlas_public_key" {
  description = "MongoDB Atlas API public key"
  type        = string
  sensitive   = true
}

variable "atlas_private_key" {
  description = "MongoDB Atlas API private key"
  type        = string
  sensitive   = true
}

