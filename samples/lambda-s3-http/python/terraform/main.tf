# Lambda S3 HTTP Sample - Terraform Configuration

locals {
  table_name     = "${var.prefix}-game-scores"
  bucket_name    = "${var.prefix}-replays"
  queue_name     = "${var.prefix}-score-validation"
  http_function  = "${var.prefix}-http-handler"
  s3_function    = "${var.prefix}-s3-handler"
  sqs_function   = "${var.prefix}-sqs-handler"
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.prefix}-lambda-s3-http-role"

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

# IAM policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.prefix}-lambda-s3-http-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.scores.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.validation.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.replays.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# DynamoDB table
resource "aws_dynamodb_table" "scores" {
  name         = local.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "playerId"

  attribute {
    name = "playerId"
    type = "S"
  }
}

# S3 bucket
resource "aws_s3_bucket" "replays" {
  bucket        = local.bucket_name
  force_destroy = true
}

# SQS queue
resource "aws_sqs_queue" "validation" {
  name = local.queue_name
}

# Package Lambda functions
data "archive_file" "http_zip" {
  type        = "zip"
  source_file = "${path.module}/../src/http_handler.py"
  output_path = "${path.module}/http.zip"
}

data "archive_file" "s3_zip" {
  type        = "zip"
  source_file = "${path.module}/../src/s3_handler.py"
  output_path = "${path.module}/s3.zip"
}

data "archive_file" "sqs_zip" {
  type        = "zip"
  source_file = "${path.module}/../src/sqs_handler.py"
  output_path = "${path.module}/sqs.zip"
}

# HTTP handler Lambda
resource "aws_lambda_function" "http_handler" {
  function_name    = local.http_function
  role             = aws_iam_role.lambda_role.arn
  handler          = "http_handler.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.http_zip.output_path
  source_code_hash = data.archive_file.http_zip.output_base64sha256
  timeout          = 30
  memory_size      = 128

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.scores.name
      QUEUE_URL  = aws_sqs_queue.validation.url
    }
  }
}

# S3 handler Lambda
resource "aws_lambda_function" "s3_handler" {
  function_name    = local.s3_function
  role             = aws_iam_role.lambda_role.arn
  handler          = "s3_handler.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.s3_zip.output_path
  source_code_hash = data.archive_file.s3_zip.output_base64sha256
  timeout          = 30
  memory_size      = 128

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.scores.name
    }
  }
}

# SQS handler Lambda
resource "aws_lambda_function" "sqs_handler" {
  function_name    = local.sqs_function
  role             = aws_iam_role.lambda_role.arn
  handler          = "sqs_handler.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.sqs_zip.output_path
  source_code_hash = data.archive_file.sqs_zip.output_base64sha256
  timeout          = 30
  memory_size      = 128

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.scores.name
    }
  }
}

# Lambda Function URL
resource "aws_lambda_function_url" "http_url" {
  function_name      = aws_lambda_function.http_handler.function_name
  authorization_type = "NONE"
}

# S3 -> Lambda permission
resource "aws_lambda_permission" "s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_handler.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.replays.arn
}

# S3 notification
resource "aws_s3_bucket_notification" "replay_notification" {
  bucket = aws_s3_bucket.replays.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_handler.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.s3_invoke]
}

# SQS -> Lambda event source mapping
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.validation.arn
  function_name    = aws_lambda_function.sqs_handler.arn
  batch_size       = 10
}
