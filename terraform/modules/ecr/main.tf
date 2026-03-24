resource "aws_ecr_repository" "this" {
  for_each = toset([
    "fcg-users-api",
    "fcg-catalog-api",
    "fcg-payments-api",
    "fcg-notifications-api",
    "fcg-lambda-payment",
    "fcg-lambda-notification",
  ])

  name                 = each.key
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}
