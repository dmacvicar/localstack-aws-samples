# ELB Load Balancing with Lambda targets
# Creates ALB with path-based routing to Lambda functions

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = var.region
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2            = var.localstack_endpoint
    lambda         = var.localstack_endpoint
    elbv2          = var.localstack_endpoint
    iam            = var.localstack_endpoint
  }
}

variable "region" {
  default = "us-east-1"
}

variable "localstack_endpoint" {
  default = "http://localhost.localstack.cloud:4566"
}

variable "lb_name" {
  default = "elb-test"
}

variable "function_prefix" {
  default = "elb-handler"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "elb-vpc"
  }
}

# Subnets
resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name = "elb-subnet-1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.region}b"

  tags = {
    Name = "elb-subnet-2"
  }
}

# Security Group
resource "aws_security_group" "elb_sg" {
  name        = "elb-sg"
  description = "Security group for ELB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "elb-sg"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "elb-lambda-role"

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

# Lambda deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../handler.js"
  output_path = "${path.module}/handler.zip"
}

# Lambda function 1
resource "aws_lambda_function" "hello1" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.function_prefix}-hello1"
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.hello1"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "nodejs18.x"
  timeout          = 30
}

# Lambda function 2
resource "aws_lambda_function" "hello2" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.function_prefix}-hello2"
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.hello2"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "nodejs18.x"
  timeout          = 30
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = var.lb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elb_sg.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  tags = {
    Name = var.lb_name
  }
}

# Target Group 1 (Lambda)
resource "aws_lb_target_group" "tg1" {
  name        = "tg-hello1"
  target_type = "lambda"
}

# Target Group 2 (Lambda)
resource "aws_lb_target_group" "tg2" {
  name        = "tg-hello2"
  target_type = "lambda"
}

# Lambda permissions for ALB
resource "aws_lambda_permission" "alb1" {
  statement_id  = "AllowExecutionFromALB"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello1.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.tg1.arn
}

resource "aws_lambda_permission" "alb2" {
  statement_id  = "AllowExecutionFromALB"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello2.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.tg2.arn
}

# Register Lambda targets
resource "aws_lb_target_group_attachment" "tg1_attachment" {
  target_group_arn = aws_lb_target_group.tg1.arn
  target_id        = aws_lambda_function.hello1.arn
  depends_on       = [aws_lambda_permission.alb1]
}

resource "aws_lb_target_group_attachment" "tg2_attachment" {
  target_group_arn = aws_lb_target_group.tg2.arn
  target_id        = aws_lambda_function.hello2.arn
  depends_on       = [aws_lambda_permission.alb2]
}

# ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

# Listener Rule for /hello1
resource "aws_lb_listener_rule" "hello1" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg1.arn
  }

  condition {
    path_pattern {
      values = ["/hello1"]
    }
  }
}

# Listener Rule for /hello2
resource "aws_lb_listener_rule" "hello2" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg2.arn
  }

  condition {
    path_pattern {
      values = ["/hello2"]
    }
  }
}

# Outputs
output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet1_id" {
  value = aws_subnet.subnet1.id
}

output "subnet2_id" {
  value = aws_subnet.subnet2.id
}

output "sg_id" {
  value = aws_security_group.elb_sg.id
}

output "lb_name" {
  value = aws_lb.main.name
}

output "lb_arn" {
  value = aws_lb.main.arn
}

output "lb_dns" {
  value = aws_lb.main.dns_name
}

output "listener_arn" {
  value = aws_lb_listener.http.arn
}

output "tg1_arn" {
  value = aws_lb_target_group.tg1.arn
}

output "tg2_arn" {
  value = aws_lb_target_group.tg2.arn
}

output "func1_name" {
  value = aws_lambda_function.hello1.function_name
}

output "func1_arn" {
  value = aws_lambda_function.hello1.arn
}

output "func2_name" {
  value = aws_lambda_function.hello2.function_name
}

output "func2_arn" {
  value = aws_lambda_function.hello2.arn
}

output "elb_url" {
  value = "http://${aws_lb.main.dns_name}:4566"
}
