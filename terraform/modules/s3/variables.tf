variable "bucket_name" {
  type        = string
  description = "The name of the S3 bucket"
}

variable "acm_certificate_arn" {
  type        = string
  description = "The ARN of the ACM certificate created manually in us-east-1"
}
/*
variable "domain_aliases" {
  type        = list(string)
  description = "List of custom domains for the CloudFront distribution"
}
*/
variable "environment" {
  type        = string
  description = "Deployment environment tag"
  default     = "Dev"
}
variable "cognito_domain" {
  type        = string
}

variable "client_id" {
  type        = string
}

variable "api_url" {
  type        = string
}