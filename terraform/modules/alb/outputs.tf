output alb_dns_name {
  value       = aws_lb.dailylog_alb.dns_name
  description = "The public URL/DNS of your Load Balancer"
}