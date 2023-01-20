output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.vpc.cidr_block
}
output "public_subnet1" {
  value = aws_subnet.public_subnet_1
}

output "public_subnet2" {
  value = aws_subnet.public_subnet_2
}

output "private_subnet1" {
  value = aws_subnet.private_subnet_1
}

output "private_subnet2" {
  value = aws_subnet.private_subnet_2
}
