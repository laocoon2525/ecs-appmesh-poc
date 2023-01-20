
resource "aws_iam_role" "task_iam_role" {
  path = "/"
  assume_role_policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Principal = { Service = [ "ecs-tasks.amazonaws.com" ]}
      Action = [ "sts:AssumeRole" ]
    }]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchFullAccess",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess",
    "arn:aws:iam::aws:policy/AWSAppMeshEnvoyAccess"
  ]
}


resource "aws_iam_role" "task_execution_iam_role" {
  path = "/"
  assume_role_policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Principal = { Service = [ "ecs-tasks.amazonaws.com" ]}
      Action = [ "sts:AssumeRole" ]
    }]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  ]
}

resource "aws_service_discovery_private_dns_namespace" "private_dns_namespace" {
  name = "${var.environment_name}.pvtdns"
  vpc = aws_vpc.vpc.id
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.environment_name
}

