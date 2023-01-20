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

module "vpc" {
  source = "../"
}
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.environment_name
}

resource "aws_security_group" "ecs_instances_security_group" {
  description = "Security group for the instances"
  vpc_id = module.vpc.vpc_id
  ingress {
    cidr_blocks      = [module.vpc.vpc_cidr]
    protocol         = -1
  }
}

resource "aws_autoscaling_group" "ecs_auto_scaling_group" {
  vpc_zone_identifier = [module.vpc.private_subnet1, module.vpc.private_subnet2]
  launch_configuration = ECSLaunchConfiguration
  min_size = var.cluster_size
  max_size = var.cluster_size

}


#ECSAutoScalingGroup:
#Type: AWS::AutoScaling::AutoScalingGroup
#Properties:
#VPCZoneIdentifier:
#- 'Fn::ImportValue': !Sub "${EnvironmentName}:PrivateSubnet1"
#- 'Fn::ImportValue': !Sub "${EnvironmentName}:PrivateSubnet2"
#LaunchConfigurationName: !Ref ECSLaunchConfiguration
#MinSize: !Ref ClusterSize
#MaxSize: !Ref ClusterSize
#DesiredCapacity: !Ref ClusterSize
#Tags:
#- Key: Name
#Value: !Sub ${EnvironmentName} ECS host
#PropagateAtLaunch: true
#CreationPolicy:
#ResourceSignal:
#Timeout: PT15M
#UpdatePolicy:
#AutoScalingRollingUpdate:
#MinInstancesInService: 1
#MaxBatchSize: 1
#PauseTime: PT15M
#SuspendProcesses:
#- HealthCheck
#- ReplaceUnhealthy
#- AZRebalance
#- AlarmNotification
#- ScheduledActions
#WaitOnResourceSignals: true
#
#ECSLaunchConfiguration:
#Type: AWS::AutoScaling::LaunchConfiguration
#Properties:
#ImageId: !Ref ECSAmi
#InstanceType: !Ref InstanceType
#KeyName: !Ref KeyName
#SecurityGroups:
#- !Ref ECSInstancesSecurityGroup
#IamInstanceProfile: !Ref ECSInstanceProfile
#UserData:
#"Fn::Base64": !Sub |
##!/bin/bash
#yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
#yum install -y aws-cfn-bootstrap hibagent
#/opt/aws/bin/cfn-init -v --region ${AWS::Region} --stack ${AWS::StackName} --resource ECSLaunchConfiguration
#/opt/aws/bin/cfn-signal -e $? --region ${AWS::Region} --stack ${AWS::StackName} --resource ECSAutoScalingGroup
#/usr/bin/enable-ec2-spot-hibernation
#
#Metadata:
#AWS::CloudFormation::Init:
#config:
#packages:
#yum:
#awslogs: []
#
#commands:
#01_add_instance_to_cluster:
#command: !Sub echo ECS_CLUSTER=${ECSCluster} >> /etc/ecs/ecs.config
#files:
#"/etc/cfn/cfn-hup.conf":
#mode: 000400
#owner: root
#group: root
#content: !Sub |
#[main]
#stack=${AWS::StackId}
#region=${AWS::Region}
#
#"/etc/cfn/hooks.d/cfn-auto-reloader.conf":
#content: !Sub |
#[cfn-auto-reloader-hook]
#triggers=post.update
#path=Resources.ECSLaunchConfiguration.Metadata.AWS::CloudFormation::Init
#action=/opt/aws/bin/cfn-init -v --region ${AWS::Region} --stack ${AWS::StackName} --resource ECSLaunchConfiguration
#
#"/etc/awslogs/awscli.conf":
#content: !Sub |
#[plugins]
#cwlogs = cwlogs
#[default]
#region = ${AWS::Region}
#
#"/etc/awslogs/awslogs.conf":
#content: !Sub |
#[general]
#state_file = /var/lib/awslogs/agent-state
#
#[/var/log/dmesg]
#file = /var/log/dmesg
#log_group_name = ${ECSCluster}-/var/log/dmesg
#log_stream_name = ${ECSCluster}
#
#[/var/log/messages]
#file = /var/log/messages
#log_group_name = ${ECSCluster}-/var/log/messages
#log_stream_name = ${ECSCluster}
#datetime_format = %b %d %H:%M:%S
#
#[/var/log/docker]
#file = /var/log/docker
#log_group_name = ${ECSCluster}-/var/log/docker
#log_stream_name = ${ECSCluster}
#datetime_format = %Y-%m-%dT%H:%M:%S.%f
#
#[/var/log/ecs/ecs-init.log]
#file = /var/log/ecs/ecs-init.log.*
#log_group_name = ${ECSCluster}-/var/log/ecs/ecs-init.log
#log_stream_name = ${ECSCluster}
#datetime_format = %Y-%m-%dT%H:%M:%SZ
#
#[/var/log/ecs/ecs-agent.log]
#file = /var/log/ecs/ecs-agent.log.*
#log_group_name = ${ECSCluster}-/var/log/ecs/ecs-agent.log
#log_stream_name = ${ECSCluster}
#datetime_format = %Y-%m-%dT%H:%M:%SZ
#
#[/var/log/ecs/audit.log]
#file = /var/log/ecs/audit.log.*
#log_group_name = ${ECSCluster}-/var/log/ecs/audit.log
#log_stream_name = ${ECSCluster}
#datetime_format = %Y-%m-%dT%H:%M:%SZ
#
#services:
#sysvinit:
#cfn-hup:
#enabled: true
#ensureRunning: true
#files:
#- /etc/cfn/cfn-hup.conf
#- /etc/cfn/hooks.d/cfn-auto-reloader.conf
#awslogsd:
#enabled: true
#ensureRunning: true
#files:
#- /etc/awslogs/awslogs.conf
#- /etc/awslogs/awscli.conf
#
## This IAM Role is attached to all of the ECS hosts. It is based on the default role
## published here:
## http://docs.aws.amazon.com/AmazonECS/latest/developerguide/instance_IAM_role.html
##
## You can add other IAM policy statements here to allow access from your ECS hosts
## to other AWS services. Please note that this role will be used by ALL containers
## running on the ECS host.
#
#ECSInstanceRole:
#Type: AWS::IAM::Role
#Properties:
#Path: /
#AssumeRolePolicyDocument: |
#{
#"Statement": [{
#"Action": "sts:AssumeRole",
#"Effect": "Allow",
#"Principal": {
#"Service": "ec2.amazonaws.com"
#}
#}]
#}
#Policies:
#- PolicyName: ecs-service
#PolicyDocument: |
#{
#"Statement": [{
#"Effect": "Allow",
#"Action": [
#"ecs:CreateCluster",
#"ecs:DeregisterContainerInstance",
#"ecs:DiscoverPollEndpoint",
#"ecs:Poll",
#"ecs:RegisterContainerInstance",
#"ecs:StartTelemetrySession",
#"ecs:Submit*",
#"logs:CreateLogStream",
#"logs:PutLogEvents",
#"ecr:BatchCheckLayerAvailability",
#"ecr:BatchGetImage",
#"ecr:GetDownloadUrlForLayer",
#"ecr:GetAuthorizationToken",
#"ssm:DescribeAssociation",
#"ssm:GetDeployablePatchSnapshotForInstance",
#"ssm:GetDocument",
#"ssm:GetManifest",
#"ssm:GetParameters",
#"ssm:ListAssociations",
#"ssm:ListInstanceAssociations",
#"ssm:PutInventory",
#"ssm:PutComplianceItems",
#"ssm:PutConfigurePackageResult",
#"ssm:UpdateAssociationStatus",
#"ssm:UpdateInstanceAssociationStatus",
#"ssm:UpdateInstanceInformation",
#"ec2messages:AcknowledgeMessage",
#"ec2messages:DeleteMessage",
#"ec2messages:FailMessage",
#"ec2messages:GetEndpoint",
#"ec2messages:GetMessages",
#"ec2messages:SendReply",
#"cloudwatch:PutMetricData",
#"ec2:DescribeInstanceStatus",
#"ds:CreateComputer",
#"ds:DescribeDirectories",
#"logs:CreateLogGroup",
#"logs:CreateLogStream",
#"logs:DescribeLogGroups",
#"logs:DescribeLogStreams",
#"logs:PutLogEvents",
#"s3:PutObject",
#"s3:GetObject",
#"s3:AbortMultipartUpload",
#"s3:ListMultipartUploadParts",
#"s3:ListBucket",
#"s3:ListBucketMultipartUploads"
#],
#"Resource": "*"
#}]
#}
#
#ECSInstanceProfile:
#Type: AWS::IAM::InstanceProfile
#Properties:
#Path: /
#Roles:
#- !Ref ECSInstanceRole
#
#ECSServiceAutoScalingRole:
#Type: AWS::IAM::Role
#Properties:
#AssumeRolePolicyDocument:
#Version: '2012-10-17'
#Statement:
#Action:
#- 'sts:AssumeRole'
#Effect: Allow
#Principal:
#Service:
#- application-autoscaling.amazonaws.com
#Path: /
#Policies:
#- PolicyName: ecs-service-autoscaling
#PolicyDocument:
#Statement:
#Effect: Allow
#Action:
#- application-autoscaling:*
#- cloudwatch:DescribeAlarms
#- cloudwatch:PutMetricAlarm
#- ecs:DescribeServices
#- ecs:UpdateService
#Resource: "*"
#
#ECSServiceSecurityGroup:
#Type: AWS::EC2::SecurityGroup
#Properties:
#GroupDescription: "Security group for the service"
#VpcId:
#'Fn::ImportValue': !Sub "${EnvironmentName}:VPC"
#SecurityGroupIngress:
#- CidrIp:
#'Fn::ImportValue': !Sub "${EnvironmentName}:VpcCIDR"
#IpProtocol: -1
#
#TaskIamRole:
#Type: AWS::IAM::Role
#Properties:
#Path: /
#AssumeRolePolicyDocument: |
#{
#"Statement": [{
#"Effect": "Allow",
#"Principal": { "Service": [ "ecs-tasks.amazonaws.com" ]},
#"Action": [ "sts:AssumeRole" ]
#}]
#}
#ManagedPolicyArns:
#- arn:aws:iam::aws:policy/CloudWatchFullAccess
#- arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess
#- arn:aws:iam::aws:policy/AWSAppMeshEnvoyAccess
#
#TaskExecutionIamRole:
#Type: AWS::IAM::Role
#Properties:
#Path: /
#AssumeRolePolicyDocument: |
#{
#"Statement": [{
#"Effect": "Allow",
#"Principal": { "Service": [ "ecs-tasks.amazonaws.com" ]},
#"Action": [ "sts:AssumeRole" ]
#}]
#}
#ManagedPolicyArns:
#- arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
#- arn:aws:iam::aws:policy/CloudWatchLogsFullAccess
#
#ECSServiceLogGroup:
#Type: 'AWS::Logs::LogGroup'
#Properties:
#RetentionInDays:
#Ref: ECSServiceLogGroupRetentionInDays
#
#ECSServiceDiscoveryNamespace:
#Type: AWS::ServiceDiscovery::PrivateDnsNamespace
#Properties:
#Vpc:
#'Fn::ImportValue': !Sub "${EnvironmentName}:VPC"
#Name: { Ref: ECSServicesDomain }
#
#BastionSecurityGroup:
#Type: AWS::EC2::SecurityGroup
#Properties:
#GroupDescription: Allow http to client host
#VpcId:
#'Fn::ImportValue': !Sub "${EnvironmentName}:VPC"
#SecurityGroupIngress:
#- IpProtocol: tcp
#FromPort: 22
#ToPort: 22
#CidrIp: 0.0.0.0/0
#
#BastionHost:
#Type: AWS::EC2::Instance
#Properties:
#ImageId: !Ref EC2Ami
#KeyName: !Ref KeyName
#InstanceType: t2.micro
#SecurityGroupIds:
#- !Ref BastionSecurityGroup
#SubnetId:
#'Fn::ImportValue': !Sub "${EnvironmentName}:PublicSubnet1"
#Tags:
#- Key: Name
#Value: bastion-host