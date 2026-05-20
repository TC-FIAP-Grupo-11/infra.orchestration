locals {
  sqlserver_host = "sqlserver-service"
}

# Pods usam IMDS (LabRole do node group) para credenciais AWS — sem env vars estáticas

resource "kubernetes_secret" "newrelic" {
  metadata {
    name      = "newrelic-secret"
    namespace = "default"
  }

  data = {
    NEW_RELIC_LICENSE_KEY = var.new_relic_license_key
  }
}

resource "kubernetes_secret" "sqlserver" {
  metadata {
    name      = "sqlserver-secret"
    namespace = "default"
  }

  data = {
    SA_PASSWORD = var.sa_password
  }
}

resource "kubernetes_secret" "users_api" {
  metadata {
    name      = "users-api-secret"
    namespace = "default"
  }

  data = {
    CONNECTION_STRING     = "Server=${local.sqlserver_host};Database=FCG_Users;User Id=sa;Password=${var.sa_password};TrustServerCertificate=True;"
    JWT_AUTHORITY         = var.cognito_authority
    COGNITO_USER_POOL_ID  = var.cognito_user_pool_id
    COGNITO_CLIENT_ID     = var.cognito_client_id
    COGNITO_CLIENT_SECRET = var.cognito_client_secret
    ADMIN_EMAIL           = var.admin_email
    ADMIN_PASSWORD        = var.admin_password
  }
}

resource "kubernetes_secret" "catalog_api" {
  metadata {
    name      = "catalog-api-secret"
    namespace = "default"
  }

  data = {
    CONNECTION_STRING          = "Server=${local.sqlserver_host};Database=FCG_Catalog;User Id=sa;Password=${var.sa_password};TrustServerCertificate=True;"
    JWT_AUTHORITY              = var.cognito_authority
    REDIS_CONNECTION_STRING    = var.redis_connection_string
    MONGODB_CONNECTION_STRING  = var.mongodb_connection_string
    ELASTICSEARCH_URL          = var.elasticsearch_url
    ELASTICSEARCH_USERNAME     = var.elasticsearch_username
    ELASTICSEARCH_PASSWORD     = var.elasticsearch_password
  }
}
