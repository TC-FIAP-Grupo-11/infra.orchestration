output "endpoint" {
  value = "https://${aws_opensearch_domain.this.endpoint}"
}

output "username" {
  value = "fcg-admin"
}

output "password" {
  value     = random_password.master.result
  sensitive = true
}
