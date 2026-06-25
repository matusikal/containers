resource "aws_cognito_user_pool" "dailylog_pool" {
  name                = "dailylog-user-pool"
  username_attributes = ["email"]
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  mfa_configuration = "OFF"
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }
}

resource "aws_cognito_user_pool_domain" "dailylog_domain" {
  domain       = "dailylog-auth-matusikal"
  user_pool_id = aws_cognito_user_pool.dailylog_pool.id
}

resource "aws_cognito_user_pool_client" "dailylog_client" {
  name         = "dailylog-web-client"
  user_pool_id = aws_cognito_user_pool.dailylog_pool.id

  generate_secret = false
  callback_urls = var.callback_urls
  logout_urls   = var.callback_urls
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  supported_identity_providers         = ["COGNITO"]
}