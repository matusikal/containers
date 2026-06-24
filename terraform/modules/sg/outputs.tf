output "alb_sg_id" {
  value       = aws_security_group.alb.id
  description = "The ID of the ALB security group"
}
output "ecs_sg_id" {
  value       = aws_security_group.ecs.id
  description = "The ID of the ECS security group"
}
output "rds_sg_id" {
  value       = aws_security_group.rds.id
  description = "The ID of the RDS security group"
}