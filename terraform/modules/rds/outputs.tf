output "rds_secret_arn" {
  value       = aws_secretsmanager_secret.rds_credentials.arn
  description = "ARN of the RDS credentials secret"
}

output "rds_endpoint" {
  value       = aws_db_instance.dailylog_db.address
  description = "RDS instance hostname"
}

output "db_password" {
  value       = random_password.db_password.result
  description = "Randomly generated password for the RDS database"
}