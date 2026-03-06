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
    iot = "http://localhost.localstack.cloud:4566"
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  thing_name  = "iot-thing-${random_id.suffix.hex}"
  policy_name = "iot-policy-${random_id.suffix.hex}"
  rule_name   = "rule_${random_id.suffix.hex}"
}

resource "aws_iot_thing" "main" {
  name = local.thing_name

  attributes = {
    env     = "test"
    version = "1.0"
  }
}

resource "aws_iot_policy" "main" {
  name = local.policy_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["iot:Connect", "iot:Publish", "iot:Subscribe", "iot:Receive"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iot_topic_rule" "main" {
  name        = local.rule_name
  enabled     = true
  sql         = "SELECT * FROM 'iot/sensor/+'"
  sql_version = "2016-03-23"
}

output "thing_name" {
  value = aws_iot_thing.main.name
}

output "thing_arn" {
  value = aws_iot_thing.main.arn
}

output "policy_name" {
  value = aws_iot_policy.main.name
}

output "policy_arn" {
  value = aws_iot_policy.main.arn
}

output "rule_name" {
  value = aws_iot_topic_rule.main.name
}

output "iot_endpoint" {
  value = ""
}
