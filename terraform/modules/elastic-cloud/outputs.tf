output "endpoint" {
  value = ec_deployment.this.elasticsearch.https_endpoint
}

output "username" {
  value = "elastic"
}

output "password" {
  value     = ec_deployment.this.elasticsearch_password
  sensitive = true
}
