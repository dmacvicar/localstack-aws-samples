terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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
    dynamodb = "http://localhost.localstack.cloud:4566"
    iam      = "http://localhost.localstack.cloud:4566"
    lambda   = "http://localhost.localstack.cloud:4566"
    sqs      = "http://localhost.localstack.cloud:4566"
  }
}

locals {
  prefix = "lambda-event-filtering"
}

# DynamoDB Table with Streams
resource "aws_dynamodb_table" "main" {
  name         = "${local.prefix}-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"
}

# SQS Queue
resource "aws_sqs_queue" "main" {
  name = "${local.prefix}-queue"
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda" {
  name = "${local.prefix}-role"

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
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_sqs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

# Lambda deployment package
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/../handler.js"
  output_path = "${path.module}/handler.zip"
}

# DynamoDB Stream Lambda function
resource "aws_lambda_function" "dynamodb_processor" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "${local.prefix}-dynamodb"
  role             = aws_iam_role.lambda.arn
  handler          = "handler.processDynamoDBStream"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "nodejs18.x"
}

# SQS Lambda function
resource "aws_lambda_function" "sqs_processor" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "${local.prefix}-sqs"
  role             = aws_iam_role.lambda.arn
  handler          = "handler.processSQS"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "nodejs18.x"
}

# DynamoDB Stream event source mapping with INSERT filter
resource "aws_lambda_event_source_mapping" "dynamodb" {
  event_source_arn  = aws_dynamodb_table.main.stream_arn
  function_name     = aws_lambda_function.dynamodb_processor.arn
  starting_position = "TRIM_HORIZON"
  batch_size        = 1

  filter_criteria {
    filter {
      pattern = jsonencode({
        eventName = ["INSERT"]
      })
    }
  }
}

# SQS event source mapping with data:A filter
resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = aws_sqs_queue.main.arn
  function_name    = aws_lambda_function.sqs_processor.arn
  batch_size       = 1

  filter_criteria {
    filter {
      pattern = jsonencode({
        body = {
          data = ["A"]
        }
      })
    }
  }
}

# Outputs
output "table_name" {
  value = aws_dynamodb_table.main.name
}

output "stream_arn" {
  value = aws_dynamodb_table.main.stream_arn
}

output "queue_name" {
  value = aws_sqs_queue.main.name
}

output "queue_url" {
  value = aws_sqs_queue.main.url
}

output "queue_arn" {
  value = aws_sqs_queue.main.arn
}

output "dynamodb_function_name" {
  value = aws_lambda_function.dynamodb_processor.function_name
}

output "sqs_function_name" {
  value = aws_lambda_function.sqs_processor.function_name
}

output "dynamodb_event_source_uuid" {
  value = aws_lambda_event_source_mapping.dynamodb.uuid
}

output "sqs_event_source_uuid" {
  value = aws_lambda_event_source_mapping.sqs.uuid
}
