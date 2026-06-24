variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for the RDS instance"
}

variable "rds_security_group_id" {
  type        = string
  description = "The ID of the dailylog-rds-sg security group"
}
