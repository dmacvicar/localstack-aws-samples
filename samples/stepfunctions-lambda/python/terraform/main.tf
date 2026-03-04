# Step Functions Lambda Sample - Terraform Configuration

locals {
  adam_function    = "${var.prefix}-sfn-adam"
  cole_function    = "${var.prefix}-sfn-cole"
  combine_function = "${var.prefix}-sfn-combine"
  state_machine    = "${var.prefix}-parallel-workflow"
}

# Lambda execution role
resource "aws_iam_role" "lambda_role" {
  name = "${var.prefix}-sfn-lambda-role"

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

# Step Functions execution role
resource "aws_iam_role" "sfn_role" {
  name = "${var.prefix}-sfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Step Functions policy to invoke Lambda
resource "aws_iam_role_policy" "sfn_lambda_invoke" {
  name = "${var.prefix}-sfn-lambda-invoke"
  role = aws_iam_role.sfn_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "lambda:InvokeFunction"
      ]
      Resource = [
        aws_lambda_function.adam.arn,
        aws_lambda_function.cole.arn,
        aws_lambda_function.combine.arn
      ]
    }]
  })
}

# Package Lambda functions
data "archive_file" "adam_zip" {
  type        = "zip"
  source_file = "${path.module}/../src/lambda_adam.py"
  output_path = "${path.module}/adam.zip"
}

data "archive_file" "cole_zip" {
  type        = "zip"
  source_file = "${path.module}/../src/lambda_cole.py"
  output_path = "${path.module}/cole.zip"
}

data "archive_file" "combine_zip" {
  type        = "zip"
  source_file = "${path.module}/../src/lambda_combine.py"
  output_path = "${path.module}/combine.zip"
}

# Adam Lambda function
resource "aws_lambda_function" "adam" {
  function_name    = local.adam_function
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_adam.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.adam_zip.output_path
  source_code_hash = data.archive_file.adam_zip.output_base64sha256
  timeout          = 30
  memory_size      = 128
}

# Cole Lambda function
resource "aws_lambda_function" "cole" {
  function_name    = local.cole_function
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_cole.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.cole_zip.output_path
  source_code_hash = data.archive_file.cole_zip.output_base64sha256
  timeout          = 30
  memory_size      = 128
}

# Combine Lambda function
resource "aws_lambda_function" "combine" {
  function_name    = local.combine_function
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_combine.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.combine_zip.output_path
  source_code_hash = data.archive_file.combine_zip.output_base64sha256
  timeout          = 30
  memory_size      = 128
}

# Step Functions state machine
resource "aws_sfn_state_machine" "parallel_workflow" {
  name     = local.state_machine
  role_arn = aws_iam_role.sfn_role.arn

  definition = jsonencode({
    Comment = "A parallel state machine that demonstrates Step Functions orchestrating multiple Lambda functions"
    StartAt = "Parallel State"
    States = {
      "Parallel State" = {
        Type = "Parallel"
        Next = "Combine"
        Branches = [
          {
            StartAt = "Adam"
            States = {
              Adam = {
                Type     = "Task"
                Resource = "arn:aws:states:::lambda:invoke"
                OutputPath = "$.Payload"
                Parameters = {
                  FunctionName = aws_lambda_function.adam.arn
                  Payload = {
                    "input.$" = "$"
                  }
                }
                End = true
              }
            }
          },
          {
            StartAt = "Cole"
            States = {
              Cole = {
                Type     = "Task"
                Resource = "arn:aws:states:::lambda:invoke"
                OutputPath = "$.Payload"
                Parameters = {
                  FunctionName = aws_lambda_function.cole.arn
                  Payload = {
                    "input.$" = "$"
                  }
                }
                End = true
              }
            }
          }
        ]
      }
      Combine = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        OutputPath = "$.Payload"
        Parameters = {
          FunctionName = aws_lambda_function.combine.arn
          Payload = {
            "input.$" = "$"
          }
        }
        End = true
      }
    }
  })
}
