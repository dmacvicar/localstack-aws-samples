# Cognito JWT Authentication
# Creates User Pool, Client, and test users

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
    cognitoidp = var.localstack_endpoint
  }
}

variable "region" {
  default = "us-east-1"
}

variable "localstack_endpoint" {
  default = "http://localhost.localstack.cloud:4566"
}

variable "pool_name" {
  default = "test-user-pool"
}

variable "client_name" {
  default = "test-client"
}

# Cognito User Pool
resource "aws_cognito_user_pool" "main" {
  name = var.pool_name

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = false
  }

  auto_verified_attributes = ["email"]

  tags = {
    Name = var.pool_name
  }
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "main" {
  name         = var.client_name
  user_pool_id = aws_cognito_user_pool.main.id

  explicit_auth_flows = [
    "ADMIN_NO_SRP_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]
}

# Outputs
output "pool_name" {
  value = aws_cognito_user_pool.main.name
}

output "pool_id" {
  value = aws_cognito_user_pool.main.id
}

output "pool_arn" {
  value = aws_cognito_user_pool.main.arn
}

output "client_name" {
  value = aws_cognito_user_pool_client.main.name
}

output "client_id" {
  value = aws_cognito_user_pool_client.main.id
}
