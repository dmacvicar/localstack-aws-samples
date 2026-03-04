#!/usr/bin/env python3
"""Lambda Function URLs Sample - CDK Stack."""

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


class LambdaFunctionUrlStack(Stack):
    """CDK Stack for Lambda Function URL sample."""

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # Lambda execution role
        role = iam.Role(
            self, "LambdaRole",
            role_name="lambda-function-url-cdk-role",
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

def handler(event, context):
    """Handle HTTP requests via Lambda Function URL."""
    http_method = event.get("requestContext", {}).get("http", {}).get("method", "UNKNOWN")
    path = event.get("requestContext", {}).get("http", {}).get("path", "/")
    query_params = event.get("queryStringParameters") or {}

    body = event.get("body")
    if body:
        try:
            body = json.loads(body)
        except (json.JSONDecodeError, TypeError):
            pass

    response_body = {
        "message": "Hello from Lambda Function URL!",
        "request": {
            "method": http_method,
            "path": path,
            "queryParams": query_params,
            "body": body
        },
        "functionName": context.function_name if context else "unknown"
    }

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(response_body)
    }
'''

        fn = lambda_.Function(
            self, "Handler",
            function_name="lambda-function-url-cdk",
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
LambdaFunctionUrlStack(
    app, "LambdaFunctionUrlStack",
    env=cdk.Environment(
        account=os.environ.get("CDK_DEFAULT_ACCOUNT", "000000000000"),
        region=os.environ.get("CDK_DEFAULT_REGION", "us-east-1"),
    ),
)
app.synth()
