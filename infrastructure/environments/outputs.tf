output "alb_hostname" {
  value = aws_alb.alb.dns_name
}

output "public_subnets" {
  value = aws_subnet.public_subnet
  description = "public subnets"
}