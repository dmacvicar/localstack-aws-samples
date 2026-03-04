terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider configuration
# Use tflocal (terraform-local) to automatically route to LocalStack
# Install: pip install terraform-local
# Run: tflocal init && tflocal apply
provider "aws" {
  region = var.region
}
