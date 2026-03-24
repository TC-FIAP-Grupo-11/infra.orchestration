output "api_endpoint" {
  description = "Public endpoint of the AWS API Gateway"
  value       = aws_apigatewayv2_api.fcg.api_endpoint
}

output "api_id" {
  value = aws_apigatewayv2_api.fcg.id
}

output "vpc_link_id" {
  value = aws_apigatewayv2_vpc_link.fcg.id
}
