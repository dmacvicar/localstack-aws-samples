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
    mq = "http://localhost.localstack.cloud:4566"
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  broker_name = "mq-broker-${random_id.suffix.hex}"
  username    = "admin"
  password    = "Admin123456!"
}

resource "aws_mq_broker" "main" {
  broker_name        = local.broker_name
  engine_type        = "ActiveMQ"
  engine_version     = "5.18"
  host_instance_type = "mq.m5.large"
  deployment_mode    = "SINGLE_INSTANCE"
  publicly_accessible = true
  auto_minor_version_upgrade = true

  user {
    username       = local.username
    password       = local.password
    console_access = true
    groups         = ["admin"]
  }
}

output "broker_id" {
  value = aws_mq_broker.main.id
}

output "broker_name" {
  value = local.broker_name
}

output "broker_arn" {
  value = aws_mq_broker.main.arn
}

output "console_url" {
  value = try(aws_mq_broker.main.instances[0].console_url, "")
}

output "username" {
  value = local.username
}

output "password" {
  value     = local.password
  sensitive = true
}
