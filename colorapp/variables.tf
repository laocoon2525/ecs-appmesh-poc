variable "port" {
  description = "port of application"
  type = number
  default = 8080
}

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