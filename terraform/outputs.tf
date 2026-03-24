output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "ecr_urls" {
  value = module.ecr.repository_urls
}

output "lambda_payment_arn" {
  value = module.lambda.payment_function_arn
}

output "lambda_notification_arn" {
  value = module.lambda.notification_function_arn
}

output "api_gateway_endpoint" {
  description = "URL pública do AWS API Gateway — ponto de entrada único para todos os microsserviços"
  value       = module.apigateway.api_endpoint
}
