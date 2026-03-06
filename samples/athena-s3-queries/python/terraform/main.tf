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
    s3     = "http://localhost.localstack.cloud:4566"
    athena = "http://localhost.localstack.cloud:4566"
    glue   = "http://localhost.localstack.cloud:4566"
  }

  s3_use_path_style = true
}

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  bucket_name   = "athena-test-${random_id.suffix.hex}"
  database_name = "test_db"
  table_name    = "test_table1"
}

# S3 bucket for data and results
resource "aws_s3_bucket" "athena_bucket" {
  bucket        = local.bucket_name
  force_destroy = true
}

# Upload test data
resource "aws_s3_object" "test_data" {
  bucket = aws_s3_bucket.athena_bucket.id
  key    = "data/data.csv"
  source = "${path.module}/../data/data.csv"
  etag   = filemd5("${path.module}/../data/data.csv")
}

# Glue catalog database (Athena uses Glue Data Catalog)
resource "aws_glue_catalog_database" "test_db" {
  name         = local.database_name
  location_uri = "s3://${local.bucket_name}/test_db/"
}

# Glue catalog table
resource "aws_glue_catalog_table" "test_table" {
  name          = local.table_name
  database_name = aws_glue_catalog_database.test_db.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "skip.header.line.count" = "1"
    "EXTERNAL"               = "TRUE"
  }

  storage_descriptor {
    location      = "s3://${local.bucket_name}/data/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = {
        "field.delim" = ","
      }
    }

    columns {
      name = "id"
      type = "int"
    }
    columns {
      name = "first_name"
      type = "string"
    }
    columns {
      name = "last_name"
      type = "string"
    }
    columns {
      name = "email"
      type = "string"
    }
    columns {
      name = "gender"
      type = "string"
    }
    columns {
      name = "is_active"
      type = "boolean"
    }
    columns {
      name = "joined_date"
      type = "string"
    }
  }

  depends_on = [aws_s3_object.test_data]
}

# Athena workgroup
resource "aws_athena_workgroup" "main" {
  name = "athena-workgroup-${random_id.suffix.hex}"

  configuration {
    result_configuration {
      output_location = "s3://${local.bucket_name}/results/"
    }
  }

  force_destroy = true
}

output "bucket_name" {
  value = local.bucket_name
}

output "database_name" {
  value = local.database_name
}

output "table_name" {
  value = local.table_name
}

output "workgroup_name" {
  value = aws_athena_workgroup.main.name
}

output "s3_output" {
  value = "s3://${local.bucket_name}/results"
}
