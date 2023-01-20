resource "aws_vpc" "vpc" {
  enable_dns_hostnames = true
  cidr_block = var.vpc_cidr
  tags = {
    "Name" = "DEMO"
  }
}


resource "aws_internet_gateway" "internet_gateway" {
  tags = {
    "Name" = "DEMO"
  }
}

resource "aws_internet_gateway_attachment" "internet_gateway_attachment" {
  internet_gateway_id = aws_internet_gateway.internet_gateway.id
  vpc_id              = aws_vpc.vpc.id
}


resource "aws_subnet" "public_subnet_1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.public_subnet1_cidr
  availability_zone = var.availability_zone_1
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.environment_name} Public Subnet (AZ1)"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.public_subnet2_cidr
  availability_zone = var.availability_zone_2
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.environment_name} Public Subnet (AZ2)"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.private_subnet1_cidr
  availability_zone = var.availability_zone_1
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.environment_name} Private Subnet (AZ1)"
    "kubernetes.io/role/internal-elb" = 1
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.private_subnet2_cidr
  availability_zone = var.availability_zone_2
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.environment_name} Private Subnet (AZ2)"
    "kubernetes.io/role/internal-elb" = 1
  }
}


resource "aws_eip" "nat_gateway_1_eip" {
  vpc = true
  # ? Domain
  depends_on                = [aws_internet_gateway_attachment.internet_gateway_attachment]
}

resource "aws_eip" "nat_gateway_2_eip" {
  vpc = true
  # ? Domain
  depends_on                = [aws_internet_gateway_attachment.internet_gateway_attachment]
}

resource "aws_nat_gateway" "nat_gateway_1" {
  subnet_id = aws_subnet.public_subnet_1.id
  allocation_id = aws_eip.nat_gateway_1_eip.id
}

resource "aws_nat_gateway" "nat_gateway_2" {
  subnet_id = aws_subnet.public_subnet_2.id
  allocation_id = aws_eip.nat_gateway_2_eip.id
}

### Public routes
resource "aws_route_table" "route_table" { #PublicRouteTable
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.environment_name} Public Routes"
  }
}

resource "aws_route" "default_public_route" {
  route_table_id = aws_route_table.route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.internet_gateway.id
  depends_on = [aws_internet_gateway_attachment.internet_gateway_attachment]
}

resource "aws_route_table_association" "public_subnet_1_route_table_association" {
  route_table_id = aws_route_table.route_table.id
  subnet_id = aws_subnet.public_subnet_1.id
}

resource "aws_route_table_association" "public_subnet_2_route_table_association" {
  route_table_id = aws_route_table.route_table.id
  subnet_id = aws_subnet.public_subnet_2.id
}

### Private routes
resource "aws_route_table" "private_route_table1" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.environment_name} Private Routes (AZ1)"
  }
}

resource "aws_route" "default_private_route1" {
  route_table_id = aws_route_table.private_route_table1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_nat_gateway.nat_gateway_1.id
}

resource "aws_route_table_association" "private_subnet_1_route_table_association" {
  route_table_id = aws_route_table.private_route_table1.id
  subnet_id = aws_subnet.private_subnet_1.id
}

resource "aws_route_table" "private_route_table2" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.environment_name} Private Routes (AZ2)"
  }
}

resource "aws_route" "default_private_route2" {
  route_table_id = aws_route_table.private_route_table2.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_nat_gateway.nat_gateway_2.id
}

resource "aws_route_table_association" "private_subnet_2_route_table_association" {
  route_table_id = aws_route_table.private_route_table2.id
  subnet_id = aws_subnet.private_subnet_2.id
}
