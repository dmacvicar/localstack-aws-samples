output "function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.handler.function_name
}

output "api_id" {
  description = "API Gateway API ID"
  value       = aws_apigatewayv2_api.http_api.id
}

output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}

output "domain_name" {
  description = "Custom domain name"
  value       = var.domain_name
}

output "cert_arn" {
  description = "ACM certificate ARN"
  value       = aws_acm_certificate.cert.arn
}

output "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}
