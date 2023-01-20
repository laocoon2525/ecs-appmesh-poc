terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.50.0"
    }
  }
}
provider "aws" {
  region = "us-west-2"
}

resource "aws_appmesh_mesh" "appmesh_mesh" {
  name = var.mesh_name
}