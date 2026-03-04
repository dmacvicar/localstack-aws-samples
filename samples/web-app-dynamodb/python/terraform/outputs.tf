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

output "table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.items.name
}

output "table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.items.arn
}
