variable "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer (ALB) to which the API Gateway will proxy requests."
  type        = string
}
variable "user_pool_id" {
  description = "The ID of the Cognito User Pool for JWT authentication."
  type        = string
}
variable "user_pool_client_id" {
  description = "The Client ID of the Cognito User Pool for JWT authentication."
  type        = string
}