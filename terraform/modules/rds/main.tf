resource "aws_db_subnet_group" "default" {      #subnet group creation
  name       = "main"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "My DB subnet group"
  }
}

resource "random_id" "snapshot_suffix" {
  byte_length = 4
}

resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_instance" "dailylog_db" {
  identifier           = "dailylog-db"
  engine               = "postgres"
  engine_version       = "16"             
  instance_class       = "db.t3.micro" 
  allocated_storage    = 20
  storage_type         = "gp3"            
  db_name              = "dailylog"
  username             = "dailylog_admin"
  password             = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.default.name
  availability_zone      = "eu-central-1a"
  publicly_accessible    = false
  vpc_security_group_ids = [var.rds_security_group_id]
  backup_retention_period = 7
  deletion_protection     = false
  skip_final_snapshot     = false
  final_snapshot_identifier = "dailylog-final-snapshot-${random_id.snapshot_suffix.hex}"

  tags = {
    Name = "dailylog-db"
  }
}

resource "aws_secretsmanager_secret" "rds_credentials" {
  name        = "dailylog/rds/credentials"
  description = "RDS credentials for dailylog app"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "rds_credentials_val" {
  secret_id     = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = "dailylog_admin"
    password = random_password.db_password.result
    dbname   = "dailylog"
    host     = aws_db_instance.dailylog_db.address
    port     = aws_db_instance.dailylog_db.port
  })
}

