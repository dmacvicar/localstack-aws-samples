# Lambda Function URLs Sample (JavaScript) - Terraform Configuration

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    lambda = var.localstack_endpoint
    iam    = var.localstack_endpoint
  }
}

variable "localstack_endpoint" {
  description = "LocalStack endpoint URL"
  default     = "http://localhost.localstack.cloud:4566"
}

variable "suffix" {
  description = "Resource name suffix"
  default     = ""
}

locals {
  suffix        = var.suffix != "" ? var.suffix : formatdate("YYYYMMDDhhmmss", timestamp())
  function_name = "lambda-url-js-${local.suffix}"
}

# Package the Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../index.js"
  output_path = "${path.module}/function.zip"
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda-role-${local.suffix}"

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
  handler          = "index.handler"
  runtime          = "nodejs18.x"
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

output "function_name" {
  value = aws_lambda_function.handler.function_name
}

output "function_url" {
  value = aws_lambda_function_url.handler_url.function_url
}

output "role_name" {
  value = aws_iam_role.lambda_role.name
}
