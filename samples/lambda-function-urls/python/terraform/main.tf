# Lambda Function URLs Sample - Terraform Configuration

locals {
  function_name = "${var.prefix}-${var.function_name}"
}

# Package the Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../src/handler.py"
  output_path = "${path.module}/function.zip"
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${local.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Lambda function
resource "aws_lambda_function" "handler" {
  function_name    = local.function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  timeout     = 30
  memory_size = 128
}

# Lambda Function URL
resource "aws_lambda_function_url" "handler_url" {
  function_name      = aws_lambda_function.handler.function_name
  authorization_type = "NONE"
}

# Permission for public access to Function URL
resource "aws_lambda_permission" "function_url_public" {
  statement_id           = "FunctionURLAllowPublicAccess"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.handler.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}
