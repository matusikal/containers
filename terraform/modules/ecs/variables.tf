variable "execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}
variable "task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}
variable "ecr_image_url" {
  description = "URL of the ECR image to be used in the ECS task"
  type        = string
}
variable "rds_endpoint" {
  description = "Endpoint of the RDS instance"
  type        = string
}
variable "private_subnet_ids" {
  description = "List of private subnet IDs for the ECS service"
  type        = list(string)
}
variable "ecs_sg_id" {
  description = "Security group ID for the ECS service"
  type        = string
}
variable "target_group_arn" {
  description = "ARN of the target group for the ECS service"
  type        = string
}