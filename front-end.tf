resource "aws_lb_target_group" "front_target_group" {
  health_check {
    port = var.app_port
    protocol = "HTTP"
    interval = 60
    path = "/ping"
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
  target_type = "ip"
  name = "${var.environment_name}-front"
  port = var.app_port
  protocol = "HTTP"
  # TODO missing following config, do we need it?
  #TargetGroupAttributes:
  #- Key: deregistration_delay.timeout_seconds
  #Value: 120
  vpc_id = aws_vpc.vpc.id
}


resource "aws_appmesh_virtual_node" "front_virtual_node" {
  mesh_name = aws_appmesh_mesh.appmesh_mesh.name
  name      = "${var.environment_name}-front-node"
  spec {
    listener {
      port_mapping {
        port     = var.app_port
        protocol = "http"
      }
    }
    service_discovery {
      dns {
        hostname = aws_lb.public_load_balancer.dns_name
      }
    }
    backend {
      virtual_service {
        virtual_service_name = aws_appmesh_virtual_service.color_virtual_service.name
      }
    }
  }
}

resource "aws_ecs_task_definition" "front_task_def" {
  requires_compatibilities = ["FARGATE"]
  family = "${var.environment_name}-front"
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
  depends_on = [aws_appmesh_virtual_node.front_virtual_node]
  container_definitions    = <<TASK_DEFINITION
[
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
                    "value": "howto-ecs-basics-front-node"
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
            "name": "app",
            "image": "753465955229.dkr.ecr.us-west-2.amazonaws.com/howto-ecs-basics/feapp:b65f866",
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
                    "name": "COLOR_HOST",
                    "value": "color.howto-ecs-basics.mesh.local:8080"
                },
                {
                    "name": "XRAY_APP_NAME",
                    "value": "front"
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
                    "awslogs-stream-prefix": "front"
                },
                "secretOptions": []
            },
            "systemControls": []
        },
        {
            "name": "envoy",
            "image": "public.ecr.aws/appmesh/aws-appmesh-envoy:v1.24.0.0-prod",
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
                    "value": "mesh/howto-ecs-basics/virtualNode/howto-ecs-basics-front-node"
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
                    "awslogs-stream-prefix": "front"
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
        },
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
                    "awslogs-stream-prefix": "front"
                },
                "secretOptions": []
            },
            "systemControls": []
        }
    ]
TASK_DEFINITION
}

resource "aws_ecs_service" "front_ecs_service" {
  name = "front_ecs_service"
  depends_on = [aws_lb_listener.public_load_balancer_listener, aws_alb_listener_rule.front_listener_rule]
  cluster = var.environment_name

  task_definition = aws_ecs_task_definition.front_task_def.arn
  desired_count = 1

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  launch_type = "FARGATE"

  load_balancer {
    container_name = "app"
    container_port = var.app_port
    target_group_arn = aws_lb_target_group.front_target_group.arn
  }

  network_configuration {
    assign_public_ip = false
    security_groups = [aws_security_group.app_security_group.id,]
    subnets = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  }

}

#FrontECSService:
#Type: AWS::ECS::Service
#DependsOn:
#- PublicLoadBalancerListener
#- FrontListenerRule
#Properties:
#Cluster: !Ref ECSCluster
#DeploymentConfiguration:
#MaximumPercent: 200
#MinimumHealthyPercent: 100
#DesiredCount: 3
#LaunchType: 'FARGATE'
#TaskDefinition: !Ref FrontTaskDef
#LoadBalancers:
#- ContainerName: app
#ContainerPort: !Ref ContainerPort
#TargetGroupArn: !Ref FrontTargetGroup
#NetworkConfiguration:
#AwsvpcConfiguration:
#AssignPublicIp: DISABLED
#SecurityGroups:
#- !Ref AppSecurityGroup
#Subnets:
#- !Ref PrivateSubnet1
#- !Ref PrivateSubnet2