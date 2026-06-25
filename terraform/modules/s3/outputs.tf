output "s3_distribution_domain_name" {
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
  description = "CloudFront distribution URL for the S3 bucket"
}