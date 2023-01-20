variable "environment_name" {
  description = "An environment name that will be prefixed to resource names"
  type = string
  default = "DEMO"
}

variable "vpc_cidr" {
  description = "Please enter the IP range (CIDR notation) for this VPC"
  type = string
  default = "10.0.0.0/16"
}

variable "public_subnet1_cidr" {
  description = "Please enter the IP range (CIDR notation) for the public subnet in the first Availability Zone"
  type = string
  default = "10.0.0.0/19"
}

variable "public_subnet2_cidr" {
  description = "Please enter the IP range (CIDR notation) for the public subnet in the second Availability Zone"
  type = string
  default = "10.0.32.0/19"
}

variable "private_subnet1_cidr" {
  description = "Please enter the IP range (CIDR notation) for the private subnet in the first Availability Zone"
  type = string
  default = "10.0.64.0/19"
}

variable "private_subnet2_cidr" {
  description = "Please enter the IP range (CIDR notation) for the private subnet in the second Availability Zone"
  type = string
  default = "10.0.96.0/19"
}

variable "availability_zone_1" {
  description = "Availability Zone 1"
  type = string
  default = "us-west-2a"
}

variable "availability_zone_2" {
  description = "Availability Zone 2"
  type = string
  default = "us-west-2b"
}

variable "mesh_name" {
  description = "Name for the appmesh"
  type = string
  default = "appmesh-mesh"
}

variable "app_port" {
  description = "App port"
  type = number
  default = 8080
}