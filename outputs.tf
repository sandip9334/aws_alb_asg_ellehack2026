
output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = aws_lb.app.dns_name
}

output "target_group_arn" {
  description = "Target Group ARN"
  value       = aws_lb_target_group.app_tg.arn
}
