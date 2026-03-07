#!/usr/bin/env python3
"""CDK app for ELB Load Balancing with Lambda targets."""

import os
from pathlib import Path

import aws_cdk as cdk
from aws_cdk import (
    Stack,
    aws_ec2 as ec2,
    aws_lambda as lambda_,
    aws_elasticloadbalancingv2 as elbv2,
    aws_elasticloadbalancingv2_targets as targets,
    aws_iam as iam,
    CfnOutput,
)
from constructs import Construct


class ElbLoadBalancingStack(Stack):
    """Stack for ELB with Lambda targets."""

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # Configuration
        lb_name = os.environ.get("LB_NAME", "elb-test")
        function_prefix = os.environ.get("FUNCTION_PREFIX", "elb-handler")

        # VPC
        vpc = ec2.Vpc(
            self,
            "ElbVpc",
            vpc_name="elb-vpc",
            ip_addresses=ec2.IpAddresses.cidr("10.0.0.0/16"),
            max_azs=2,
            nat_gateways=0,
            subnet_configuration=[
                ec2.SubnetConfiguration(
                    name="public",
                    subnet_type=ec2.SubnetType.PUBLIC,
                    cidr_mask=24,
                )
            ],
        )

        # Security Group
        security_group = ec2.SecurityGroup(
            self,
            "ElbSg",
            vpc=vpc,
            security_group_name="elb-sg",
            description="Security group for ELB",
            allow_all_outbound=True,
        )
        security_group.add_ingress_rule(
            ec2.Peer.any_ipv4(),
            ec2.Port.tcp(80),
            "Allow HTTP",
        )

        # Lambda Role
        lambda_role = iam.Role(
            self,
            "LambdaRole",
            role_name="elb-lambda-role",
            assumed_by=iam.ServicePrincipal("lambda.amazonaws.com"),
            managed_policies=[
                iam.ManagedPolicy.from_aws_managed_policy_name(
                    "service-role/AWSLambdaBasicExecutionRole"
                )
            ],
        )

        # Get handler code path
        handler_path = Path(__file__).parent.parent

        # Lambda Function 1
        func1 = lambda_.Function(
            self,
            "Hello1",
            function_name=f"{function_prefix}-hello1",
            runtime=lambda_.Runtime.NODEJS_18_X,
            handler="handler.hello1",
            code=lambda_.Code.from_asset(str(handler_path), exclude=["cdk", "terraform", "cloudformation", "scripts", "__pycache__", "*.pyc"]),
            role=lambda_role,
            timeout=cdk.Duration.seconds(30),
        )

        # Lambda Function 2
        func2 = lambda_.Function(
            self,
            "Hello2",
            function_name=f"{function_prefix}-hello2",
            runtime=lambda_.Runtime.NODEJS_18_X,
            handler="handler.hello2",
            code=lambda_.Code.from_asset(str(handler_path), exclude=["cdk", "terraform", "cloudformation", "scripts", "__pycache__", "*.pyc"]),
            role=lambda_role,
            timeout=cdk.Duration.seconds(30),
        )

        # Application Load Balancer
        alb = elbv2.ApplicationLoadBalancer(
            self,
            "Alb",
            load_balancer_name=lb_name,
            vpc=vpc,
            internet_facing=True,
            security_group=security_group,
        )

        # Listener
        listener = alb.add_listener(
            "HttpListener",
            port=80,
            protocol=elbv2.ApplicationProtocol.HTTP,
            default_action=elbv2.ListenerAction.fixed_response(
                status_code=404,
                content_type="text/plain",
                message_body="Not Found",
            ),
        )

        # Target Group 1
        tg1 = listener.add_targets(
            "Hello1Target",
            target_group_name="tg-hello1",
            targets=[targets.LambdaTarget(func1)],
            priority=1,
            conditions=[elbv2.ListenerCondition.path_patterns(["/hello1"])],
        )

        # Target Group 2
        tg2 = listener.add_targets(
            "Hello2Target",
            target_group_name="tg-hello2",
            targets=[targets.LambdaTarget(func2)],
            priority=2,
            conditions=[elbv2.ListenerCondition.path_patterns(["/hello2"])],
        )

        # Outputs
        CfnOutput(self, "VpcId", value=vpc.vpc_id)
        CfnOutput(self, "Subnet1Id", value=vpc.public_subnets[0].subnet_id)
        CfnOutput(self, "Subnet2Id", value=vpc.public_subnets[1].subnet_id if len(vpc.public_subnets) > 1 else vpc.public_subnets[0].subnet_id)
        CfnOutput(self, "SgId", value=security_group.security_group_id)
        CfnOutput(self, "LBName", value=alb.load_balancer_name)
        CfnOutput(self, "LBArn", value=alb.load_balancer_arn)
        CfnOutput(self, "LBDNS", value=alb.load_balancer_dns_name)
        CfnOutput(self, "ListenerArn", value=listener.listener_arn)
        CfnOutput(self, "TG1Arn", value=tg1.target_group_arn)
        CfnOutput(self, "TG2Arn", value=tg2.target_group_arn)
        CfnOutput(self, "Func1Name", value=func1.function_name)
        CfnOutput(self, "Func1Arn", value=func1.function_arn)
        CfnOutput(self, "Func2Name", value=func2.function_name)
        CfnOutput(self, "Func2Arn", value=func2.function_arn)
        CfnOutput(self, "ELBURL", value=f"http://{alb.load_balancer_dns_name}:4566")


app = cdk.App()
ElbLoadBalancingStack(
    app,
    "ElbLoadBalancingStack",
    env=cdk.Environment(
        account=os.environ.get("CDK_DEFAULT_ACCOUNT", "000000000000"),
        region=os.environ.get("CDK_DEFAULT_REGION", "us-east-1"),
    ),
)
app.synth()
