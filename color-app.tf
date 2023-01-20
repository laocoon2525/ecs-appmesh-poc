resource "aws_service_discovery_service" "color_service_registry" {
  name = "color"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.private_dns_namespace.id
    dns_records {
      ttl  = 300
      type = "A"
    }
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ecs_task_definition" "color_task_def" {
  requires_compatibilities = ["FARGATE"]
  family = "${var.environment_name}-color"
  network_mode = "awsvpc"
  cpu = 256
  memory = 512
  task_role_arn = aws_iam_role.task_iam_role.arn
  execution_role_arn = aws_iam_role.task_execution_iam_role.arn
  proxy_configuration {
    type           = "APPMESH"
    container_name = "envoy"
    properties = {
      AppPorts         = var.app_port
      EgressIgnoredIPs = "169.254.170.2,169.254.169.254"
      IgnoredUID       = "1337"
      ProxyEgressPort  = 15001
      ProxyIngressPort = 15000
    }
  }
  container_definitions    = <<TASK_DEFINITION
[
        {
            "name": "xray",
            "image": "public.ecr.aws/xray/aws-xray-daemon",
            "cpu": 0,
            "links": [],
            "portMappings": [
                {
                    "containerPort": 2000,
                    "hostPort": 2000,
                    "protocol": "udp"
                }
            ],
            "essential": true,
            "entryPoint": [],
            "command": [],
            "environment": [],
            "environmentFiles": [],
            "mountPoints": [],
            "volumesFrom": [],
            "secrets": [],
            "user": "1337",
            "dnsServers": [],
            "dnsSearchDomains": [],
            "extraHosts": [],
            "dockerSecurityOptions": [],
            "dockerLabels": {},
            "ulimits": [],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "howto-ecs-basics-log-group",
                    "awslogs-region": "us-west-2",
                    "awslogs-stream-prefix": "color"
                },
                "secretOptions": []
            },
            "systemControls": []
        },
        {
            "name": "app",
            "image": "753465955229.dkr.ecr.us-west-2.amazonaws.com/howto-ecs-basics/colorapp:b65f866",
            "cpu": 0,
            "links": [],
            "portMappings": [
                {
                    "containerPort": 8080,
                    "hostPort": 8080,
                    "protocol": "tcp"
                }
            ],
            "essential": true,
            "entryPoint": [],
            "command": [],
            "environment": [
                {
                    "name": "PORT",
                    "value": "8080"
                },
                {
                    "name": "COLOR",
                    "value": "green"
                },
                {
                    "name": "XRAY_APP_NAME",
                    "value": "color"
                }
            ],
            "environmentFiles": [],
            "mountPoints": [],
            "volumesFrom": [],
            "secrets": [],
            "dependsOn": [
                {
                    "containerName": "envoy",
                    "condition": "HEALTHY"
                },
                {
                    "containerName": "xray",
                    "condition": "START"
                }
            ],
            "dnsServers": [],
            "dnsSearchDomains": [],
            "extraHosts": [],
            "dockerSecurityOptions": [],
            "dockerLabels": {},
            "ulimits": [],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "howto-ecs-basics-log-group",
                    "awslogs-region": "us-west-2",
                    "awslogs-stream-prefix": "color"
                },
                "secretOptions": []
            },
            "systemControls": []
        },
        {
            "name": "cwagent",
            "image": "753465955229.dkr.ecr.us-west-2.amazonaws.com/howto-ecs-basics/cwagent:9b29b35",
            "cpu": 0,
            "links": [],
            "portMappings": [
                {
                    "containerPort": 8125,
                    "hostPort": 8125,
                    "protocol": "udp"
                }
            ],
            "essential": true,
            "entryPoint": [],
            "command": [],
            "environment": [
                {
                    "name": "HOST_NAME",
                    "value": "howto-ecs-basics-color-node"
                },
                {
                    "name": "CW_CONFIG_CONTENT",
                    "value": "{ \"metrics\": { \"namespace\":\"howto-ecs-basics\", \"metrics_collected\": { \"statsd\": {}}}}"
                }
            ],
            "environmentFiles": [],
            "mountPoints": [],
            "volumesFrom": [],
            "secrets": [],
            "user": "1337",
            "dnsServers": [],
            "dnsSearchDomains": [],
            "extraHosts": [],
            "dockerSecurityOptions": [],
            "dockerLabels": {},
            "ulimits": [],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "howto-ecs-basics-log-group",
                    "awslogs-region": "us-west-2",
                    "awslogs-stream-prefix": "cwagent"
                },
                "secretOptions": []
            },
            "systemControls": []
        },
        {
            "name": "envoy",
            "image": "1.14.0",
            "cpu": 0,
            "links": [],
            "portMappings": [
                {
                    "containerPort": 15001,
                    "hostPort": 15001,
                    "protocol": "tcp"
                },
                {
                    "containerPort": 15000,
                    "hostPort": 15000,
                    "protocol": "tcp"
                },
                {
                    "containerPort": 9901,
                    "hostPort": 9901,
                    "protocol": "tcp"
                }
            ],
            "essential": true,
            "entryPoint": [],
            "command": [],
            "environment": [
                {
                    "name": "ENABLE_ENVOY_DOG_STATSD",
                    "value": "1"
                },
                {
                    "name": "ENABLE_ENVOY_XRAY_TRACING",
                    "value": "1"
                },
                {
                    "name": "ENABLE_ENVOY_STATS_TAGS",
                    "value": "1"
                },
                {
                    "name": "APPMESH_VIRTUAL_NODE_NAME",
                    "value": "mesh/howto-ecs-basics/virtualNode/howto-ecs-basics-color-node"
                },
                {
                    "name": "ENVOY_LOG_LEVEL",
                    "value": "debug"
                }
            ],
            "environmentFiles": [],
            "mountPoints": [],
            "volumesFrom": [],
            "secrets": [],
            "dependsOn": [
                {
                    "containerName": "xray",
                    "condition": "START"
                }
            ],
            "user": "1337",
            "dnsServers": [],
            "dnsSearchDomains": [],
            "extraHosts": [],
            "dockerSecurityOptions": [],
            "dockerLabels": {},
            "ulimits": [
                {
                    "name": "nofile",
                    "softLimit": 15000,
                    "hardLimit": 15000
                }
            ],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "howto-ecs-basics-log-group",
                    "awslogs-region": "us-west-2",
                    "awslogs-stream-prefix": "color"
                },
                "secretOptions": []
            },
            "healthCheck": {
                "command": [
                    "CMD-SHELL",
                    "curl -s http://localhost:9901/server_info | grep state | grep -q LIVE"
                ],
                "interval": 5,
                "timeout": 10,
                "retries": 10
            },
            "systemControls": []
        }
    ]
TASK_DEFINITION
}


resource "aws_ecs_service" "color_ecs_service" {
  name = "color_ecs_service"
  depends_on = [aws_service_discovery_service.color_service_registry]
  cluster = var.environment_name

  task_definition = aws_ecs_task_definition.color_task_def.arn
  desired_count = 1

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  launch_type = "FARGATE"

  service_registries {
    registry_arn = aws_service_discovery_service.color_service_registry.arn
  }
  network_configuration {
    assign_public_ip = false
    security_groups = [aws_security_group.app_security_group.id,]
    subnets = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  }

}

resource "aws_appmesh_virtual_node" "color_virtual_node" {
  mesh_name = aws_appmesh_mesh.appmesh_mesh.name
  name      = "${var.environment_name}-color-node"
  spec {
    listener {
      port_mapping {
        port     = var.app_port
        protocol = "http"
      }
    }
    service_discovery {
      aws_cloud_map {
        namespace_name = "${var.environment_name}.pvtdns"
        service_name   = aws_service_discovery_service.color_service_registry.name
        attributes = {
          ECS_TASK_DEFINITION_FAMILY = "${var.environment_name}-color"
        }
      }
    }
  }
}

resource "aws_appmesh_virtual_service" "color_virtual_service" {
  mesh_name = aws_appmesh_mesh.appmesh_mesh.name
  name      = "${aws_service_discovery_service.color_service_registry.name}-${var.environment_name}.mesh.local"
  spec {
    provider {
      virtual_node {
        virtual_node_name = aws_appmesh_virtual_node.color_virtual_node.name
      }
    }
  }
}