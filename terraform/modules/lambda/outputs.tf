output "payment_function_arn" {
  value = aws_lambda_function.payment.arn
}

output "notification_function_arn" {
  value = aws_lambda_function.notification.arn
}
