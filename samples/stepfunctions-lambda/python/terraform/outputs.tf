output "adam_function" {
  description = "Adam Lambda function name"
  value       = aws_lambda_function.adam.function_name
}

output "adam_arn" {
  description = "Adam Lambda function ARN"
  value       = aws_lambda_function.adam.arn
}

output "cole_function" {
  description = "Cole Lambda function name"
  value       = aws_lambda_function.cole.function_name
}

output "cole_arn" {
  description = "Cole Lambda function ARN"
  value       = aws_lambda_function.cole.arn
}

output "combine_function" {
  description = "Combine Lambda function name"
  value       = aws_lambda_function.combine.function_name
}

output "combine_arn" {
  description = "Combine Lambda function ARN"
  value       = aws_lambda_function.combine.arn
}

output "state_machine_name" {
  description = "Step Functions state machine name"
  value       = aws_sfn_state_machine.parallel_workflow.name
}

output "state_machine_arn" {
  description = "Step Functions state machine ARN"
  value       = aws_sfn_state_machine.parallel_workflow.arn
}
