output "table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.scores.name
}

output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.replays.id
}

output "queue_name" {
  description = "SQS queue name"
  value       = aws_sqs_queue.validation.name
}

output "queue_url" {
  description = "SQS queue URL"
  value       = aws_sqs_queue.validation.url
}

output "http_function" {
  description = "HTTP handler function name"
  value       = aws_lambda_function.http_handler.function_name
}

output "s3_function" {
  description = "S3 handler function name"
  value       = aws_lambda_function.s3_handler.function_name
}

output "sqs_function" {
  description = "SQS handler function name"
  value       = aws_lambda_function.sqs_handler.function_name
}
