#!/usr/bin/env python3
"""CDK app for Lambda Function URLs sample (JavaScript)."""

import os
from pathlib import Path

from aws_cdk import App, CfnOutput, Duration, Stack
from aws_cdk import aws_iam as iam
from aws_cdk import aws_lambda as lambda_
from constructs import Construct


class LambdaFunctionUrlsStack(Stack):
    """Stack for Lambda function with Function URL."""

    def __init__(self, scope: Construct, construct_id: str, suffix: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # IAM role for Lambda
        role = iam.Role(
            self,
            "LambdaRole",
            role_name=f"lambda-role-{suffix}",
            assumed_by=iam.ServicePrincipal("lambda.amazonaws.com"),
        )

        # Lambda function
        handler = lambda_.Function(
            self,
            "Handler",
            function_name=f"lambda-url-js-{suffix}",
            runtime=lambda_.Runtime.NODEJS_18_X,
            handler="index.handler",
            code=lambda_.Code.from_asset(
                str(Path(__file__).parent.parent),
                exclude=["cdk", "cdk.out", "scripts", "terraform", "cloudformation", "*.pyc", "__pycache__", "test_*"],
            ),
            role=role,
            timeout=Duration.seconds(30),
            memory_size=128,
        )

        # Function URL
        function_url = handler.add_function_url(
            auth_type=lambda_.FunctionUrlAuthType.NONE,
        )

        # Outputs
        CfnOutput(self, "FunctionNameOutput", value=handler.function_name, export_name=f"FunctionName-{suffix}")
        CfnOutput(self, "FunctionUrlOutput", value=function_url.url, export_name=f"FunctionUrl-{suffix}")
        CfnOutput(self, "RoleNameOutput", value=role.role_name, export_name=f"RoleName-{suffix}")


app = App()
suffix = os.environ.get("SUFFIX", "cdk")
LambdaFunctionUrlsStack(app, "LambdaFunctionUrlsJsStack", suffix=suffix)
app.synth()
