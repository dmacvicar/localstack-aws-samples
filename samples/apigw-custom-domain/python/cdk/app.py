#!/usr/bin/env python3
"""API Gateway Custom Domain Sample - CDK Stack."""

import os
import aws_cdk as cdk
from aws_cdk import (
    Stack,
    aws_lambda as lambda_,
    aws_iam as iam,
    aws_apigatewayv2 as apigwv2,
    aws_apigatewayv2_integrations as integrations,
    aws_certificatemanager as acm,
    aws_route53 as route53,
    CfnOutput,
    Duration,
)
from constructs import Construct


class ApiGwCustomDomainStack(Stack):
    """CDK Stack for API Gateway Custom Domain sample."""

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        domain_name = "api.example.com"
        hosted_zone_name = "example.com"

        # Get certificate ARN from context (set by deploy script)
        cert_arn = self.node.try_get_context("cert_arn")

        # Route53 Hosted Zone
        hosted_zone = route53.HostedZone(
            self, "HostedZone",
            zone_name=hosted_zone_name,
        )

        # Lambda execution role
        role = iam.Role(
            self, "LambdaRole",
            role_name="apigw-custom-domain-cdk-role",
            assumed_by=iam.ServicePrincipal("lambda.amazonaws.com"),
            managed_policies=[
                iam.ManagedPolicy.from_aws_managed_policy_name(
                    "service-role/AWSLambdaBasicExecutionRole"
                )
            ],
        )

        # Lambda function with inline code
        handler_code = '''
import json

def hello(event, context):
    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Hello from custom domain!"})
    }

def goodbye(event, context):
    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Goodbye from custom domain!"})
    }
'''

        fn = lambda_.Function(
            self, "Handler",
            function_name="apigw-custom-domain-cdk",
            runtime=lambda_.Runtime.PYTHON_3_11,
            handler="index.hello",
            code=lambda_.Code.from_inline(handler_code),
            role=role,
            timeout=Duration.seconds(30),
            memory_size=128,
        )

        # HTTP API
        http_api = apigwv2.HttpApi(
            self, "HttpApi",
            api_name="apigw-custom-domain-cdk",
        )

        # Lambda integration
        lambda_integration = integrations.HttpLambdaIntegration(
            "LambdaIntegration",
            fn,
        )

        # Add routes
        http_api.add_routes(
            path="/hello",
            methods=[apigwv2.HttpMethod.GET],
            integration=lambda_integration,
        )

        http_api.add_routes(
            path="/goodbye",
            methods=[apigwv2.HttpMethod.GET],
            integration=lambda_integration,
        )

        # Custom domain (only if cert_arn is provided)
        if cert_arn:
            certificate = acm.Certificate.from_certificate_arn(
                self, "Certificate", cert_arn
            )

            custom_domain = apigwv2.DomainName(
                self, "CustomDomain",
                domain_name=domain_name,
                certificate=certificate,
            )

            # API mapping
            apigwv2.ApiMapping(
                self, "ApiMapping",
                api=http_api,
                domain_name=custom_domain,
            )

            # Route53 record
            route53.CnameRecord(
                self, "DnsRecord",
                zone=hosted_zone,
                record_name="api",
                domain_name=custom_domain.regional_domain_name,
                ttl=Duration.minutes(5),
            )

            CfnOutput(self, "CertArn", value=cert_arn)

        # Outputs
        CfnOutput(self, "FunctionName", value=fn.function_name)
        CfnOutput(self, "ApiId", value=http_api.api_id)
        CfnOutput(self, "ApiEndpoint", value=http_api.api_endpoint)
        CfnOutput(self, "DomainName", value=domain_name)
        CfnOutput(self, "HostedZoneId", value=hosted_zone.hosted_zone_id)


app = cdk.App()
ApiGwCustomDomainStack(
    app, "ApiGwCustomDomainStack",
    env=cdk.Environment(
        account=os.environ.get("CDK_DEFAULT_ACCOUNT", "000000000000"),
        region=os.environ.get("CDK_DEFAULT_REGION", "us-east-1"),
    ),
)
app.synth()
