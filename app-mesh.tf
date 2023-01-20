resource "aws_appmesh_mesh" "appmesh_mesh" {
  name = var.mesh_name
}

resource "aws_route53_zone" "app_mesh_hosted_zone" {
  name = "${var.environment_name}.mesh.local"
  vpc {
    vpc_id = aws_vpc.vpc.id
    vpc_region = "us-west-2"
  }
}

resource "aws_route53_record" "app_mesh_wildcard_recordset" {
  name    = "${var.environment_name}.mesh.local"
  type    = "A"
  zone_id = aws_route53_zone.app_mesh_hosted_zone.id
  ttl = 900
  records = ["1.2.3.4"]
}