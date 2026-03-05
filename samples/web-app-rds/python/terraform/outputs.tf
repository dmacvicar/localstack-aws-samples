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

output "db_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.postgres.identifier
}

output "db_host" {
  description = "RDS endpoint address"
  value       = aws_db_instance.postgres.address
}

output "db_port" {
  description = "RDS endpoint port"
  value       = aws_db_instance.postgres.port
}
