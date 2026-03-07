#!/usr/bin/env python3
"""
Chalice REST API CDK application.

Replicates Chalice app functionality using standard Lambda + API Gateway.
"""

import os
from pathlib import Path

from aws_cdk import (
    App,
    CfnOutput,
    Duration,
    Stack,
    aws_apigateway as apigateway,
    aws_iam as iam,
    aws_lambda as lambda_,
)
from constructs import Construct


class ChaliceRestApiStack(Stack):
    """Stack for Chalice REST API resources."""

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # Get path to handler
        sample_dir = Path(__file__).parent.parent
        handler_path = sample_dir / "handler.py"

        # Lambda execution role
        lambda_role = iam.Role(
            self,
            "LambdaRole",
            assumed_by=iam.ServicePrincipal("lambda.amazonaws.com"),
            managed_policies=[
                iam.ManagedPolicy.from_aws_managed_policy_name(
                    "service-role/AWSLambdaBasicExecutionRole"
                )
            ],
        )

        # Lambda function
        api_function = lambda_.Function(
            self,
            "ApiFunction",
            function_name="todo-api",
            runtime=lambda_.Runtime.PYTHON_3_11,
            handler="handler.handler",
            code=lambda_.Code.from_asset(str(sample_dir), exclude=["cdk/*", "terraform/*", "cloudformation/*", "scripts/*", ".chalice/*", "__pycache__/*", "*.pyc"]),
            role=lambda_role,
            timeout=Duration.seconds(30),
        )

        # API Gateway REST API
        api = apigateway.RestApi(
            self,
            "TodoApi",
            rest_api_name="todo-app",
            deploy_options=apigateway.StageOptions(stage_name="api"),
        )

        # Lambda integration
        lambda_integration = apigateway.LambdaIntegration(api_function)

        # Root endpoint (GET /)
        api.root.add_method("GET", lambda_integration)

        # /health endpoint
        health = api.root.add_resource("health")
        health.add_method("GET", lambda_integration)

        # /introspect endpoint
        introspect = api.root.add_resource("introspect")
        introspect.add_method("GET", lambda_integration)

        # /todo endpoint
        todo = api.root.add_resource("todo")
        todo.add_method("GET", lambda_integration)
        todo.add_method("POST", lambda_integration)

        # /todo/{todo_id} endpoint
        todo_item = todo.add_resource("{todo_id}")
        todo_item.add_method("GET", lambda_integration)
        todo_item.add_method("POST", lambda_integration)
        todo_item.add_method("PUT", lambda_integration)
        todo_item.add_method("DELETE", lambda_integration)

        # Outputs
        CfnOutput(self, "ApiId", value=api.rest_api_id)
        CfnOutput(self, "FunctionName", value=api_function.function_name)
        CfnOutput(
            self,
            "ApiUrl",
            value=f"http://localhost.localstack.cloud:4566/restapis/{api.rest_api_id}/api/_user_request_",
        )


app = App()
ChaliceRestApiStack(app, "ChaliceRestApiStack")
app.synth()
