output "connection_string" {
  value     = "mongodb+srv://${mongodbatlas_database_user.app.username}:${random_password.db.result}@${trimprefix(mongodbatlas_cluster.this.connection_strings[0].standard_srv, "mongodb+srv://")}/fcg_catalog?retryWrites=true&w=majority"
  sensitive = true
}
