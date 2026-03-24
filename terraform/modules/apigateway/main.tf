# Data sources — NLBs criados pelo Kubernetes via annotation aws-load-balancer-type
data "aws_lb" "users" {
  tags = { "kubernetes.io/service-name" = "default/users-api-service" }
}
data "aws_lb" "catalog" {
  tags = { "kubernetes.io/service-name" = "default/catalog-api-service" }
}
data "aws_lb" "payments" {
  tags = { "kubernetes.io/service-name" = "default/payments-api-service" }
}
data "aws_lb" "notifications" {
  tags = { "kubernetes.io/service-name" = "default/notifications-api-service" }
}

# Listeners dos NLBs (porta 80) — API Gateway VPC Link exige listener ARN
data "aws_lb_listener" "users" {
  load_balancer_arn = data.aws_lb.users.arn
  port              = 80
}
data "aws_lb_listener" "catalog" {
  load_balancer_arn = data.aws_lb.catalog.arn
  port              = 80
}
data "aws_lb_listener" "payments" {
  load_balancer_arn = data.aws_lb.payments.arn
  port              = 80
}
data "aws_lb_listener" "notifications" {
  load_balancer_arn = data.aws_lb.notifications.arn
  port              = 80
}

# HTTP API — mais barato que REST API, suficiente para proxy de microsserviços
resource "aws_apigatewayv2_api" "fcg" {
  name          = "fcg-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
  }
}

# VPC Link — ponte entre API Gateway e a VPC privada do EKS
resource "aws_apigatewayv2_vpc_link" "fcg" {
  name               = "fcg-vpc-link"
  subnet_ids         = var.private_subnet_ids
  security_group_ids = [var.node_security_group_id]
}


# Mapeamento de serviços: nome → ARN do NLB (resolvido via data source)
locals {
  services = {
    users = {
      path         = "/users/{proxy+}"
      listener_arn = data.aws_lb_listener.users.arn
    }
    catalog = {
      path         = "/catalog/{proxy+}"
      listener_arn = data.aws_lb_listener.catalog.arn
    }
    payments = {
      path         = "/payments/{proxy+}"
      listener_arn = data.aws_lb_listener.payments.arn
    }
    notifications = {
      path         = "/notifications/{proxy+}"
      listener_arn = data.aws_lb_listener.notifications.arn
    }
  }
}

# Uma integration por serviço (HTTP_PROXY via VPC Link → NLB)
resource "aws_apigatewayv2_integration" "services" {
  for_each = local.services

  api_id             = aws_apigatewayv2_api.fcg.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = each.value.listener_arn
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.fcg.id
  integration_method = "ANY"
}

# Uma route por serviço — autenticação delegada aos microsserviços
resource "aws_apigatewayv2_route" "services" {
  for_each = local.services

  api_id             = aws_apigatewayv2_api.fcg.id
  route_key          = "ANY ${each.value.path}"
  target             = "integrations/${aws_apigatewayv2_integration.services[each.key].id}"
  authorization_type = "NONE"
}

# Stage $default com auto-deploy
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.fcg.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format          = jsonencode({
      requestId      = "$context.requestId"
      sourceIp       = "$context.identity.sourceIp"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      responseLength = "$context.responseLength"
      integrationError = "$context.integrationErrorMessage"
    })
  }
}

# CloudWatch Log Group para access logs do API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/fcg-api"
  retention_in_days = 7
}
