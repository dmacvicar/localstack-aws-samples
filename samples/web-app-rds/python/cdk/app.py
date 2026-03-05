#!/usr/bin/env python3
"""Web App RDS Sample - CDK Stack."""

import os
import aws_cdk as cdk
from aws_cdk import (
    Stack,
    aws_lambda as lambda_,
    aws_iam as iam,
    aws_rds as rds,
    aws_ec2 as ec2,
    CfnOutput,
    Duration,
    RemovalPolicy,
)
from constructs import Construct


class WebAppRdsStack(Stack):
    """CDK Stack for Web App RDS sample."""

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        db_name = "appdb"
        db_user = "admin"
        db_password = "localstack123"

        # Lambda execution role
        role = iam.Role(
            self, "LambdaRole",
            role_name="webapp-rds-cdk-role",
            assumed_by=iam.ServicePrincipal("lambda.amazonaws.com"),
            managed_policies=[
                iam.ManagedPolicy.from_aws_managed_policy_name(
                    "service-role/AWSLambdaBasicExecutionRole"
                )
            ],
        )

        # VPC for RDS (required by CDK)
        vpc = ec2.Vpc(
            self, "Vpc",
            max_azs=2,
            nat_gateways=0,
            subnet_configuration=[
                ec2.SubnetConfiguration(
                    name="private",
                    subnet_type=ec2.SubnetType.PRIVATE_ISOLATED,
                )
            ],
        )

        # RDS PostgreSQL instance
        db_instance = rds.DatabaseInstance(
            self, "PostgresInstance",
            instance_identifier="webapp-postgres-cdk",
            engine=rds.DatabaseInstanceEngine.postgres(
                version=rds.PostgresEngineVersion.VER_13_4
            ),
            instance_type=ec2.InstanceType.of(
                ec2.InstanceClass.T3, ec2.InstanceSize.MICRO
            ),
            vpc=vpc,
            vpc_subnets=ec2.SubnetSelection(subnet_type=ec2.SubnetType.PRIVATE_ISOLATED),
            database_name=db_name,
            credentials=rds.Credentials.from_username(
                db_user,
                password=cdk.SecretValue.unsafe_plain_text(db_password)
            ),
            allocated_storage=20,
            removal_policy=RemovalPolicy.DESTROY,
            deletion_protection=False,
        )

        # Lambda function with inline code
        handler_code = '''
import json
import logging
import os
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

DB_HOST = os.environ.get("DB_HOST", "localhost")
DB_PORT = os.environ.get("DB_PORT", "5432")
DB_NAME = os.environ.get("DB_NAME", "appdb")
DB_USER = os.environ.get("DB_USER", "admin")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "password")

ITEMS = {}

def handler(event, context):
    logger.info("Received event: %s", json.dumps(event))
    http_method = event.get("httpMethod", "GET")
    path = event.get("path", "/")
    path_params = event.get("pathParameters") or {}
    body = event.get("body")

    if body and isinstance(body, str):
        try:
            body = json.loads(body)
        except json.JSONDecodeError:
            pass

    try:
        if path == "/items" and http_method == "GET":
            return response(200, {"items": list(ITEMS.values())})
        elif path == "/items" and http_method == "POST":
            item_id = body.get("id") if body else f"item-{datetime.utcnow().strftime('%Y%m%d%H%M%S%f')}"
            item = {"id": item_id, "name": body.get("name", ""), "description": body.get("description", ""),
                    "category": body.get("category", "general"), "price": body.get("price", 0),
                    "created_at": datetime.utcnow().isoformat(), "updated_at": datetime.utcnow().isoformat()}
            ITEMS[item_id] = item
            return response(201, item)
        elif path.startswith("/items/") and http_method == "GET":
            item_id = path_params.get("id") or path.split("/")[-1]
            item = ITEMS.get(item_id)
            if not item:
                return response(404, {"error": f"Item {item_id} not found"})
            return response(200, item)
        elif path.startswith("/items/") and http_method == "PUT":
            item_id = path_params.get("id") or path.split("/")[-1]
            if item_id not in ITEMS:
                return response(404, {"error": f"Item {item_id} not found"})
            item = ITEMS[item_id]
            for field in ["name", "description", "category", "price"]:
                if body and field in body:
                    item[field] = body[field]
            item["updated_at"] = datetime.utcnow().isoformat()
            return response(200, item)
        elif path.startswith("/items/") and http_method == "DELETE":
            item_id = path_params.get("id") or path.split("/")[-1]
            if item_id not in ITEMS:
                return response(404, {"error": f"Item {item_id} not found"})
            del ITEMS[item_id]
            return response(204, None)
        elif path == "/health":
            return response(200, {"status": "healthy", "database": "simulated", "timestamp": datetime.utcnow().isoformat()})
        else:
            return response(404, {"error": "Not found"})
    except Exception as e:
        logger.error("Error: %s", e)
        return response(500, {"error": str(e)})

def response(status_code, body):
    resp = {"statusCode": status_code, "headers": {"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"}}
    if body is not None:
        resp["body"] = json.dumps(body)
    return resp
'''

        fn = lambda_.Function(
            self, "Handler",
            function_name="webapp-rds-cdk",
            runtime=lambda_.Runtime.PYTHON_3_12,
            handler="index.handler",
            code=lambda_.Code.from_inline(handler_code),
            role=role,
            timeout=Duration.seconds(30),
            memory_size=128,
            environment={
                "DB_HOST": db_instance.db_instance_endpoint_address,
                "DB_PORT": db_instance.db_instance_endpoint_port,
                "DB_NAME": db_name,
                "DB_USER": db_user,
                "DB_PASSWORD": db_password,
            },
        )

        # Function URL with public access
        fn_url = fn.add_function_url(
            auth_type=lambda_.FunctionUrlAuthType.NONE,
        )

        # Outputs
        CfnOutput(self, "FunctionName", value=fn.function_name)
        CfnOutput(self, "FunctionArn", value=fn.function_arn)
        CfnOutput(self, "FunctionUrl", value=fn_url.url)
        CfnOutput(self, "DBInstanceId", value=db_instance.instance_identifier)
        CfnOutput(self, "DBHost", value=db_instance.db_instance_endpoint_address)
        CfnOutput(self, "DBPort", value=db_instance.db_instance_endpoint_port)


app = cdk.App()
WebAppRdsStack(
    app, "WebAppRdsStack",
    env=cdk.Environment(
        account=os.environ.get("CDK_DEFAULT_ACCOUNT", "000000000000"),
        region=os.environ.get("CDK_DEFAULT_REGION", "us-east-1"),
    ),
)
app.synth()
