resource "random_password" "db" {
  length  = 16
  special = false
}

resource "mongodbatlas_project" "this" {
  name   = "fcg-games"
  org_id = var.atlas_org_id
}

resource "mongodbatlas_cluster" "this" {
  project_id = mongodbatlas_project.this.id
  name       = "fcg-cluster"

  # M0 free tier — requer provider_name = "TENANT"
  provider_name               = "TENANT"
  backing_provider_name       = "AWS"
  provider_region_name        = "US_EAST_1"
  provider_instance_size_name = "M0"
}

resource "mongodbatlas_database_user" "app" {
  username           = "fcg-app"
  password           = random_password.db.result
  project_id         = mongodbatlas_project.this.id
  auth_database_name = "admin"

  roles {
    role_name     = "readWrite"
    database_name = "fcg_catalog"
  }

  depends_on = [mongodbatlas_cluster.this]
}

resource "mongodbatlas_project_ip_access_list" "eks" {
  project_id = mongodbatlas_project.this.id
  cidr_block = "0.0.0.0/0"
  comment    = "Allow EKS nodes (NAT Gateway IP)"
}
