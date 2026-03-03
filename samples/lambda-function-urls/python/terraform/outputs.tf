output "function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.handler.function_name
}

output "function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.handler.arn
}

output "function_url" {
  description = "Lambda Function URL endpoint"
  value       = aws_lambda_function_url.handler_url.function_url
}

output "role_arn" {
  description = "IAM role ARN"
  value       = aws_iam_role.lambda_role.arn
}
