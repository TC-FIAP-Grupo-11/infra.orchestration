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

variable "lambda_payment_image_uri" {
  description = "ECR image URI for the Payment Lambda"
  type        = string
  default     = ""
}

variable "lambda_notification_image_uri" {
  description = "ECR image URI for the Notification Lambda"
  type        = string
  default     = ""
}

