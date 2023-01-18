variable "name" {
  description = "Name to be used on all the resources as identifier."
  type        = string
  default     = "appmesh-ecs"
}

variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "lb_ingress_ip" {
  description = "Your IP. This is used in the load balancer security groups to ensure only you can access the UI of example application."
  type        = string
}