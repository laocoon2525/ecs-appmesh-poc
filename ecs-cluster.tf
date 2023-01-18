data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

locals {
  // TF marks SSM Parameter values as sensitive by default. No need to hide this AMI ID though.
  ecs_optimized_ami = nonsensitive(data.aws_ssm_parameter.ecs_optimized_ami.value)
}

resource "aws_iam_role" "instance_role" {
  name = "${var.name}-raw-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  ]
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.name}-raw-ecs-instance-profile"
  role = aws_iam_role.instance_role.name
}

resource "aws_launch_configuration" "launch_config" {
  // Use name_prefix + create_before_destroy to avoid a "cannot delete" error.
  // https://github.com/hashicorp/terraform-provider-aws/issues/8485
  name_prefix = "${var.name}-raw-ecs"

  image_id             = local.ecs_optimized_ami
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name
  security_groups      = [data.aws_security_group.vpc_default.id]

  // Agent config.
  // https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-config.html
  user_data = <<EOF
#!/bin/bash
echo ECS_CLUSTER=${var.name} >> /etc/ecs/ecs.config
EOF

  key_name = null

  // In awsvpc mode, ENIs are the limited resource.
  // The smallest, cheapest instance types have a max of 2 ENIs.
  // One is used for the primary ENI, leaving only one ENI to run one Task :(
  //
  // Pricing is such that three t3a.nano instances seems to be cheapest for 3 ENIs.
  // In the ECS cluster, a t3a.nano exposes only 460 MiB of memory to schedule Tasks,
  // so we've reduced the memory requirement of our tasks to fit (compared to Fargate).
  instance_type = "t3a.nano"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_cluster" "this" {
  name = var.name
}

