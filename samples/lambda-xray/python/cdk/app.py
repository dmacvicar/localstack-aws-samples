#!/usr/bin/env python3
import os
import time
from pathlib import Path
from aws_cdk import (
    App,
    Stack,
    Duration,
    CfnOutput,
    aws_lambda as lambda_,
    aws_iam as iam,
)
from constructs import Construct


class LambdaXRayStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        suffix = os.environ.get("SUFFIX", str(int(time.time())))

        # IAM Role for Lambda
        role = iam.Role(
            self,
            "LambdaRole",
            role_name=f"xray-demo-role-{suffix}",
            assumed_by=iam.ServicePrincipal("lambda.amazonaws.com"),
            managed_policies=[
                iam.ManagedPolicy.from_aws_managed_policy_name(
                    "service-role/AWSLambdaBasicExecutionRole"
                ),
                iam.ManagedPolicy.from_aws_managed_policy_name(
                    "AWSXrayWriteOnlyAccess"
                ),
                iam.ManagedPolicy.from_aws_managed_policy_name(
                    "AWSLambda_ReadOnlyAccess"
                ),
            ],
        )

        # Lambda function with X-Ray tracing
        handler_code = '''
import os
import json
import logging
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

lambda_client = boto3.client("lambda")

def lambda_handler(event, context):
    logger.info(f"Event: {json.dumps(event)}")
    logger.info(f"Request ID: {context.aws_request_id}")

    response = lambda_client.get_account_settings()

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "X-Ray tracing demo",
            "accountUsage": response.get("AccountUsage", {}),
            "requestId": context.aws_request_id
        })
    }
'''

        fn = lambda_.Function(
            self,
            "XRayDemoFunction",
            function_name=f"xray-demo-{suffix}",
            runtime=lambda_.Runtime.PYTHON_3_11,
            handler="index.lambda_handler",
            code=lambda_.Code.from_inline(handler_code),
            role=role,
            timeout=Duration.seconds(30),
            tracing=lambda_.Tracing.ACTIVE,
        )

        # Outputs
        CfnOutput(self, "FunctionName", value=fn.function_name)
        CfnOutput(self, "FunctionArn", value=fn.function_arn)
        CfnOutput(self, "RoleName", value=role.role_name)
        CfnOutput(self, "RoleArn", value=role.role_arn)


app = App()
LambdaXRayStack(app, "LambdaXRayStack")
app.synth()
