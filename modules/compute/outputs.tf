output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "Application load balancer security group ID"
}

output "app_security_group_id" {
  value       = aws_security_group.app.id
  description = "Application server security group ID"

}

output "launch_template_id" {
  value = aws_launch_template.app.id

}

output "launch_template_latest_version" {
  value = aws_launch_template.app.latest_version
}