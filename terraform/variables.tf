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

