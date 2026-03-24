# Usa a LabRole pré-criada pelo AWS Academy
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

resource "aws_lambda_function" "payment" {
  function_name = "fcg-payment-processor"
  role          = data.aws_iam_role.lab_role.arn
  package_type  = "Image"
  image_uri     = var.payment_image_uri
  timeout       = 30
  memory_size   = 256
}

resource "aws_lambda_function" "notification" {
  function_name = "fcg-notification-sender"
  role          = data.aws_iam_role.lab_role.arn
  package_type  = "Image"
  image_uri     = var.notification_image_uri
  timeout       = 30
  memory_size   = 256
}
