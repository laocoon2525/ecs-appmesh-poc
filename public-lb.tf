resource "aws_security_group" "public_load_balancer_security_group" {
  vpc_id = aws_vpc.vpc.id
  description = "Access to the public facing load balancer"
  ingress {
    from_port = 80
    protocol  = "tcp"
    to_port   = 80
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.app_security_group.id]
  }
}

resource "aws_lb" "public_load_balancer" {
  subnets = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  security_groups    = [aws_security_group.public_load_balancer_security_group.id]
  idle_timeout = 30
  # TODO missing, do we need it?
  #  Scheme: internet-facing
}

resource "aws_lb_listener" "public_load_balancer_listener" {
  load_balancer_arn = aws_lb.public_load_balancer.arn
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.front_target_group.arn
  }
  depends_on = [aws_lb.public_load_balancer]
  port = 80
  protocol = "HTTP"
}

resource "aws_alb_listener_rule" "front_listener_rule" {
  action {
    target_group_arn = aws_lb_target_group.front_target_group.arn
    type = "forward"
  }
  condition {
    path_pattern {
      values = ["/color"]
    }
  }
  listener_arn = aws_lb_listener.public_load_balancer_listener.arn
  priority = 10
}