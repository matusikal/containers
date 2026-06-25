output "api_gateway_url" {
  value       = "${module.api.invoke_url}health"
  description = "should respond healthy"
}

output "raw_alb_url" {
  value       = "http://${module.alb.alb_dns_name}/health"
  description = "should respond 403"
}

output "site_url" {
  value = module.s3.s3_distribution_domain_name
  description = "CloudFront distribution URL for the S3 bucket"
}

output "cognito_user_pool_id" {
  value       = module.cognito.user_pool_id
  description = "The ID of the Cognito User Pool"
}