output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "Application load balancer security group ID"
}

output "app_security_group_id" {
  value       = aws_security_group.app.id
  description = "Application server security group ID"

}