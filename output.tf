output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "front_endpoint" {
  value = "http://${aws_lb.public_load_balancer.dns_name}"
}

