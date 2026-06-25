output "api_gateway_url" {
  value       = "${module.api.invoke_url}health"
  description = "should respond healthy"
}

output "raw_alb_url" {
  value       = "http://${module.alb.alb_dns_name}/health"
  description = "should respond 403"
}