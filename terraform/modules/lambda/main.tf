# Usa a LabRole pré-criada pelo AWS Academy
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  ecr_base = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
}

resource "aws_lambda_function" "payment" {
  function_name = "fcg-payment-processor"
  role          = data.aws_iam_role.lab_role.arn
  package_type  = "Image"
  image_uri     = "${local.ecr_base}/fcg-lambda-payment:latest"
  timeout       = 30
  memory_size   = 256
}

resource "aws_lambda_function" "notification" {
  function_name = "fcg-notification-sender"
  role          = data.aws_iam_role.lab_role.arn
  package_type  = "Image"
  image_uri     = "${local.ecr_base}/fcg-lambda-notification:latest"
  timeout       = 30
  memory_size   = 256
}
