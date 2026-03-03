variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "function-url-handler"
}

variable "prefix" {
  description = "Resource name prefix"
  type        = string
  default     = "local"
}
