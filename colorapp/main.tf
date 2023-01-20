data "aws_vpc" "vpc" {

}

data "aws_iam_role" "task_iam_role" {
  name = "TaskIamRole"
#  tags = {
#    Name = "${var.environment_name}-task-iam"
#  }
}

data "aws_iam_role" "task_execution_iam_role" {
  name = "TaskExecutionIamRole"
#  tags = {
#    Name = "${var.environment_name}-task-execution-iam"
#  }
}

resource "aws_security_group" "app_security_group" {
  vpc_id = data.aws_vpc.vpc.id
  ingress {
    from_port = 0
    protocol  = ""
    to_port   = 0
  }
}


##### start here

#ColorServiceRegistry:
#Type: AWS::ServiceDiscovery::Service
#Properties:
#Name: 'color'
#DnsConfig:
#NamespaceId: !GetAtt PrivateDnsNamespace.Id
#DnsRecords:
#- Type: A
#TTL: 300
#HealthCheckCustomConfig:
#FailureThreshold: 1

resource "aws_service_discovery_service" "color_service_registry" {
  name = "color"
  dns_config {
    namespace_id = ""
    dns_records {
      ttl  = 300
      type = "A"
    }
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}


#ColorTaskDef:
#Type: AWS::ECS::TaskDefinition
#Properties:
#RequiresCompatibilities:
#- 'FARGATE'
#Family: !Sub '${ProjectName}-color'
#NetworkMode: 'awsvpc'
#Cpu: 256
#Memory: 512
#TaskRoleArn: !Ref TaskIamRole
#ExecutionRoleArn: !Ref TaskExecutionIamRole
#ProxyConfiguration:
#Type: 'APPMESH'
#ContainerName: 'envoy'
#ProxyConfigurationProperties:
#- Name: 'IgnoredUID'
#Value: '1337'
#- Name: 'ProxyIngressPort'
#Value: '15000'
#- Name: 'ProxyEgressPort'
#Value: '15001'
#- Name: 'AppPorts'
#Value: !Sub '${ContainerPort}'
#- Name: 'EgressIgnoredIPs'
#Value: '169.254.170.2,169.254.169.254'
#ContainerDefinitions:
#- Name: 'app'
#Image: !Ref ColorAppImage
#Essential: true
#DependsOn:
#- ContainerName: 'envoy'
#Condition: 'HEALTHY'
#- ContainerName: 'xray'
#Condition: 'START'
#LogConfiguration:
#LogDriver: 'awslogs'
#Options:
#awslogs-group: !Ref LogGroup
#awslogs-region: !Ref AWS::Region
#awslogs-stream-prefix: 'color'
#PortMappings:
#- ContainerPort: !Ref ContainerPort
#HostPort: !Ref ContainerPort
#Protocol: 'tcp'
#Environment:
#- Name: COLOR
#Value: 'green'
#- Name: PORT
#Value: !Sub '${ContainerPort}'
#- Name: XRAY_APP_NAME
#Value: 'color'
#- Name: 'xray'
#Image: "public.ecr.aws/xray/aws-xray-daemon"
#Essential: true
#User: '1337'
#LogConfiguration:
#LogDriver: 'awslogs'
#Options:
#awslogs-group: !Ref LogGroup
#awslogs-region: !Ref AWS::Region
#awslogs-stream-prefix: 'color'
#PortMappings:
#- ContainerPort: 2000
#Protocol: 'udp'
#- Name: 'cwagent'
#Image: !Ref CloudWatchAgentImage
#Essential: true
#User: '1337'
#LogConfiguration:
#LogDriver: 'awslogs'
#Options:
#awslogs-group: !Ref LogGroup
#awslogs-region: !Ref AWS::Region
#awslogs-stream-prefix: 'cwagent'
#PortMappings:
#- ContainerPort: 8125
#Protocol: 'udp'
#Environment:
#- Name: 'HOST_NAME'
#Value: !GetAtt ColorVirtualNode.VirtualNodeName
#- Name: CW_CONFIG_CONTENT
#Value:
#Fn::Sub: "{ \"metrics\": { \"namespace\":\"${ProjectName}\", \"metrics_collected\": { \"statsd\": {}}}}"
#- Name: envoy
#Image: !Ref EnvoyImage
#Essential: true
#User: '1337'
#DependsOn:
#- ContainerName: 'xray'
#Condition: 'START'
#Ulimits:
#- Name: "nofile"
#HardLimit: 15000
#SoftLimit: 15000
#PortMappings:
#- ContainerPort: 9901
#Protocol: 'tcp'
#- ContainerPort: 15000
#Protocol: 'tcp'
#- ContainerPort: 15001
#Protocol: 'tcp'
#HealthCheck:
#Command:
#- 'CMD-SHELL'
#- 'curl -s http://localhost:9901/server_info | grep state | grep -q LIVE'
#Interval: 5
#Timeout: 10
#Retries: 10
#LogConfiguration:
#LogDriver: 'awslogs'
#Options:
#awslogs-group: !Ref LogGroup
#awslogs-region: !Ref AWS::Region
#awslogs-stream-prefix: 'color'
#Environment:
#- Name: 'ENVOY_LOG_LEVEL'
#Value: 'debug'
#- Name: 'ENABLE_ENVOY_XRAY_TRACING'
#Value: '1'
#- Name: 'ENABLE_ENVOY_STATS_TAGS'
#Value: '1'
#- Name: 'ENABLE_ENVOY_DOG_STATSD'
#Value: '1'
#- Name: 'APPMESH_VIRTUAL_NODE_NAME'
#Value:
#Fn::Join:
#- ''
#-
#- 'mesh/'
#- !GetAtt Mesh.MeshName
#- '/virtualNode/'
#- !GetAtt ColorVirtualNode.VirtualNodeName
#

resource "aws_ecs_task_definition" "color_task_def" {
  requires_compatibilities = ["FARGATE"]
  family = "${var.environment_name}-color"
  network_mode = "awsvpc"
  cpu = 256
  memory = 512
  task_role_arn = data.aws_iam_role.task_iam_role.arn
  execution_role_arn = data.aws_iam_role.task_execution_iam_role.arn
  proxy_configuration {
    type           = "APPMESH"
    container_name = "envoy"
    properties = {
      AppPorts         = var.port
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

#ColorECSService:
#Type: AWS::ECS::Service
#DependsOn:
#- ColorServiceRegistry
#Properties:
#Cluster: !Ref ECSCluster
#DeploymentConfiguration:
#MaximumPercent: 200
#MinimumHealthyPercent: 100
#DesiredCount: 3
#LaunchType: 'FARGATE'
#ServiceRegistries:
#- RegistryArn: !GetAtt 'ColorServiceRegistry.Arn'
#NetworkConfiguration:
#AwsvpcConfiguration:
#AssignPublicIp: DISABLED
#SecurityGroups:
#- !Ref AppSecurityGroup
#Subnets:
#- !Ref PrivateSubnet1
#- !Ref PrivateSubnet2
#TaskDefinition: !Ref ColorTaskDef
#

resource "aws_ecs_service" "color_ecs_service" {
  name = "color_ecs_service"
  depends_on = [aws_service_discovery_service.color_service_registry]
  cluster = var.environment_name

  task_definition = aws_ecs_task_definition.color_task_def.arn
  desired_count = 1

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  launch_type = "FARGATE"

  network_configuration {
    assign_public_ip = false

    security_groups = [
      aws_security_group.egress_all.id,
      aws_security_group.ingress_api.id,
    ]

    subnets = [
      aws_subnet.private_d.id, aws_subnet.private_e.id
    ]
  }
}

#ColorVirtualNode:
#Type: AWS::AppMesh::VirtualNode
#Properties:
#MeshName: !GetAtt Mesh.MeshName
#VirtualNodeName: !Sub '${ProjectName}-color-node'
#Spec:
#Listeners:
#- PortMapping:
#Port: !Ref ContainerPort
#Protocol: http
#ServiceDiscovery:
#AWSCloudMap:
#NamespaceName: !Sub '${ProjectName}.pvtdns'
#ServiceName: !GetAtt ColorServiceRegistry.Name
#Attributes:
#- Key: 'ECS_TASK_DEFINITION_FAMILY'
#Value: !Sub '${ProjectName}-color'
#


#ColorVirtualService:
#Type: AWS::AppMesh::VirtualService
#Properties:
#MeshName: !GetAtt Mesh.MeshName
#VirtualServiceName:
#Fn::Join:
#- '.'
#- - !GetAtt ColorServiceRegistry.Name
#- !Sub '${ProjectName}.mesh.local'
#Spec:
#Provider:
#VirtualNode:
#VirtualNodeName: !GetAtt ColorVirtualNode.VirtualNodeName