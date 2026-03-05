#!/usr/bin/env python3
"""Lambda CloudFront Sample - CDK Stack."""

import os
import aws_cdk as cdk
from aws_cdk import (
    Stack,
    aws_lambda as lambda_,
    aws_iam as iam,
    CfnOutput,
    Duration,
)
from constructs import Construct


class LambdaCloudfrontStack(Stack):
    """CDK Stack for Lambda CloudFront sample."""

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # Lambda execution role
        role = iam.Role(
            self, "LambdaRole",
            role_name="lambda-cloudfront-cdk-role",
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
import logging
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    logger.info("Received event: %s", json.dumps(event))
    path = "/"
    method = "GET"

    if "httpMethod" in event:
        path = event.get("path", "/")
        method = event.get("httpMethod", "GET")
    elif "Records" in event:
        cf_request = event["Records"][0]["cf"]["request"]
        path = cf_request.get("uri", "/")
        method = cf_request.get("method", "GET")

    response_body = {
        "message": "Hello from Lambda behind CloudFront!",
        "path": path,
        "method": method,
        "timestamp": datetime.utcnow().isoformat(),
        "origin": "lambda-cloudfront-sample"
    }

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Cache-Control": "max-age=60",
            "X-Custom-Header": "LocalStack-Sample"
        },
        "body": json.dumps(response_body)
    }
'''

        fn = lambda_.Function(
            self, "Handler",
            function_name="lambda-cloudfront-cdk",
            runtime=lambda_.Runtime.PYTHON_3_12,
            handler="index.handler",
            code=lambda_.Code.from_inline(handler_code),
            role=role,
            timeout=Duration.seconds(30),
            memory_size=128,
        )

        # Function URL with public access
        fn_url = fn.add_function_url(
            auth_type=lambda_.FunctionUrlAuthType.NONE,
        )

        # Outputs
        CfnOutput(self, "FunctionName", value=fn.function_name)
        CfnOutput(self, "FunctionArn", value=fn.function_arn)
        CfnOutput(self, "FunctionUrl", value=fn_url.url)
        CfnOutput(self, "RoleArn", value=role.role_arn)


app = cdk.App()
LambdaCloudfrontStack(
    app, "LambdaCloudfrontStack",
    env=cdk.Environment(
        account=os.environ.get("CDK_DEFAULT_ACCOUNT", "000000000000"),
        region=os.environ.get("CDK_DEFAULT_REGION", "us-east-1"),
    ),
)
app.synth()
