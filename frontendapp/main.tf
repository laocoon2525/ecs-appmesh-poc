
#start here

# START feapp

#FrontTargetGroup:
#Type: AWS::ElasticLoadBalancingV2::TargetGroup
#Properties:
#HealthCheckIntervalSeconds: 60
#HealthCheckPath: '/ping'
#HealthCheckPort: !Ref ContainerPort
#HealthCheckProtocol: HTTP
#HealthCheckTimeoutSeconds: 5
#HealthyThresholdCount: 2
#TargetType: ip
#Name: !Sub '${ProjectName}-front'
#Port: !Ref ContainerPort
#Protocol: HTTP
#UnhealthyThresholdCount: 2
#TargetGroupAttributes:
#- Key: deregistration_delay.timeout_seconds
#Value: 120
#VpcId: !Ref VPC
#
#FrontVirtualNode:
#Type: AWS::AppMesh::VirtualNode
#Properties:
#MeshName: !GetAtt Mesh.MeshName
#VirtualNodeName: !Sub "${ProjectName}-front-node"
#Spec:
#Listeners:
#- PortMapping:
#Port: !Sub '${ContainerPort}'
#Protocol: http
#ServiceDiscovery:
#DNS:
#Hostname: !GetAtt PublicLoadBalancer.DNSName
#Backends:
#- VirtualService:
#VirtualServiceName: !GetAtt ColorVirtualService.VirtualServiceName
#
#FrontTaskDef:
#Type: AWS::ECS::TaskDefinition
#DependsOn:
#- FrontVirtualNode
#Properties:
#RequiresCompatibilities:
#- 'FARGATE'
#Family: !Sub '${ProjectName}-front'
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
#Image: !Ref FrontAppImage
#Essential: true
#LogConfiguration:
#LogDriver: 'awslogs'
#Options:
#awslogs-group: !Ref LogGroup
#awslogs-region: !Ref AWS::Region
#awslogs-stream-prefix: 'front'
#PortMappings:
#- ContainerPort: !Ref ContainerPort
#Protocol: 'tcp'
#DependsOn:
#- ContainerName: 'envoy'
#Condition: 'HEALTHY'
#- ContainerName: 'xray'
#Condition: 'START'
#Environment:
#- Name: 'COLOR_HOST'
#Value:
#Fn::Join:
#- ''
#- - !GetAtt ColorVirtualService.VirtualServiceName
#- ':'
#- !Sub '${ContainerPort}'
#- Name: PORT
#Value: !Sub '${ContainerPort}'
#- Name: XRAY_APP_NAME
#Value: 'front'
#- Name: 'xray'
#Image: "public.ecr.aws/xray/aws-xray-daemon"
#Essential: true
#User: '1337'
#LogConfiguration:
#LogDriver: 'awslogs'
#Options:
#awslogs-group: !Ref LogGroup
#awslogs-region: !Ref AWS::Region
#awslogs-stream-prefix: 'front'
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
#Value: !GetAtt FrontVirtualNode.VirtualNodeName
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
#awslogs-stream-prefix: 'front'
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
#- !GetAtt FrontVirtualNode.VirtualNodeName
#
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