output "loadbalancerdns" {
  value = aws_lb.app_lb.dns_name
}