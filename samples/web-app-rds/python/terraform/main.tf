# Web App RDS Sample - Terraform Configuration

locals {
  function_name   = "${var.prefix}-webapp-rds-tf"
  db_instance_id  = "${var.prefix}-postgres-tf"
}

# Package the Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../src/app.py"
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

# VPC for RDS
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.prefix}-webapp-rds-vpc"
  }
}

# Private subnets for RDS
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name = "${var.prefix}-webapp-rds-private-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.region}b"

  tags = {
    Name = "${var.prefix}-webapp-rds-private-b"
  }
}

# DB subnet group
resource "aws_db_subnet_group" "main" {
  name       = "${var.prefix}-webapp-rds-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "${var.prefix}-webapp-rds-subnet-group"
  }
}

# RDS PostgreSQL instance
resource "aws_db_instance" "postgres" {
  identifier           = local.db_instance_id
  engine               = "postgres"
  engine_version       = "13.4"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  db_name              = var.db_name
  username             = var.db_user
  password             = var.db_password
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.main.name
}

# Lambda function
resource "aws_lambda_function" "handler" {
  function_name    = local.function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = "app.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 30
  memory_size      = 128

  environment {
    variables = {
      DB_HOST     = aws_db_instance.postgres.address
      DB_PORT     = tostring(aws_db_instance.postgres.port)
      DB_NAME     = var.db_name
      DB_USER     = var.db_user
      DB_PASSWORD = var.db_password
    }
  }

  depends_on = [aws_db_instance.postgres]
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
