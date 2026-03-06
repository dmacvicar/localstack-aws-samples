terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
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
    iam    = "http://localhost.localstack.cloud:4566"
    lambda = "http://localhost.localstack.cloud:4566"
    xray   = "http://localhost.localstack.cloud:4566"
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  function_name = "xray-demo-${random_id.suffix.hex}"
  role_name     = "xray-demo-role-${random_id.suffix.hex}"
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = local.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "xray_write" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_readonly" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess"
}

# Lambda deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../handler.py"
  output_path = "${path.module}/lambda.zip"
}

# Lambda function with X-Ray tracing
resource "aws_lambda_function" "xray_demo" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = local.function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.11"
  timeout          = 30

  tracing_config {
    mode = "Active"
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy_attachment.xray_write,
    aws_iam_role_policy_attachment.lambda_readonly,
  ]
}

output "function_name" {
  value = aws_lambda_function.xray_demo.function_name
}

output "function_arn" {
  value = aws_lambda_function.xray_demo.arn
}

output "role_name" {
  value = aws_iam_role.lambda_role.name
}

output "role_arn" {
  value = aws_iam_role.lambda_role.arn
}
