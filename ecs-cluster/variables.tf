variable "environment_name" {
  description = "An environment name that will be prefixed to resource names"
  type = string
  default = "DEMO"
}

variable "instance_type" {
  description = "Which instance type should we use to build the ECS cluster?"
  type = string
  default = "c4.large"
}

variable "cluster_size" {
  description = "Which instance type should we use to build the ECS cluster?"
  type = number
  default = 1
}

variable "ecs_service_log_group_retention_in_days" {
  type = number
  default = 30
}

variable "ECSServicesDomain" {
  description = "Domain name registered under Route-53 that will be used for Service Discovery"
  type = string
  default = "demo.local"
}

variable "ecs_ami" {
  description = "ECS AMI ID"
  type = string
  default = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

variable "ec2_ami" {
  description = "EC2 AMI ID"
  type = string
  default = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}