output "user_pool_id" {
    value = aws_cognito_user_pool.dailylog_pool.id
    description = "The ID of the Cognito User Pool"
}
output "user_pool_client_id" {
    value = aws_cognito_user_pool_client.dailylog_client.id
    description = "The ID of the Cognito User Pool Client"
}
output "cognito_domain" {
    value = aws_cognito_user_pool_domain.dailylog_domain.domain
    description = "The domain of the Cognito User Pool"
}