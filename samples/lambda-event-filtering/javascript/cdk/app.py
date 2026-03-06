#!/usr/bin/env python3
"""CDK app for Lambda Event Filtering sample."""

import os
from pathlib import Path

import aws_cdk as cdk
from aws_cdk import (
    Stack,
    aws_dynamodb as dynamodb,
    aws_lambda as lambda_,
    aws_lambda_event_sources as lambda_event_sources,
    aws_sqs as sqs,
    aws_iam as iam,
    CfnOutput,
    RemovalPolicy,
    Duration,
)
from constructs import Construct


class LambdaEventFilteringStack(Stack):
    """Stack for Lambda event filtering with DynamoDB Streams and SQS."""

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        project_dir = Path(__file__).parent.parent

        # DynamoDB Table with Streams (let CDK generate unique name)
        table = dynamodb.Table(
            self,
            "Table",
            partition_key=dynamodb.Attribute(
                name="id",
                type=dynamodb.AttributeType.STRING,
            ),
            billing_mode=dynamodb.BillingMode.PAY_PER_REQUEST,
            stream=dynamodb.StreamViewType.NEW_IMAGE,
            removal_policy=RemovalPolicy.DESTROY,
        )

        # SQS Queue (let CDK generate unique name)
        queue = sqs.Queue(
            self,
            "Queue",
            removal_policy=RemovalPolicy.DESTROY,
        )

        # IAM Role for Lambda (let CDK generate unique name)
        lambda_role = iam.Role(
            self,
            "LambdaRole",
            assumed_by=iam.ServicePrincipal("lambda.amazonaws.com"),
            managed_policies=[
                iam.ManagedPolicy.from_aws_managed_policy_name(
                    "service-role/AWSLambdaBasicExecutionRole"
                ),
                iam.ManagedPolicy.from_aws_managed_policy_name(
                    "AmazonDynamoDBFullAccess"
                ),
                iam.ManagedPolicy.from_aws_managed_policy_name(
                    "AmazonSQSFullAccess"
                ),
            ],
        )

        # Lambda code asset
        lambda_code = lambda_.Code.from_asset(
            str(project_dir),
            exclude=[
                "node_modules",
                "scripts",
                ".serverless",
                "*.pyc",
                "__pycache__",
                "terraform",
                "cloudformation",
                "cdk",
                "test_*.py",
            ],
        )

        # DynamoDB Stream Lambda Function (let CDK generate unique name)
        dynamodb_fn = lambda_.Function(
            self,
            "DynamoDBProcessorFunction",
            runtime=lambda_.Runtime.NODEJS_18_X,
            handler="handler.processDynamoDBStream",
            code=lambda_code,
            role=lambda_role,
            timeout=Duration.seconds(30),
        )

        # SQS Lambda Function (let CDK generate unique name)
        sqs_fn = lambda_.Function(
            self,
            "SQSProcessorFunction",
            runtime=lambda_.Runtime.NODEJS_18_X,
            handler="handler.processSQS",
            code=lambda_code,
            role=lambda_role,
            timeout=Duration.seconds(30),
        )

        # DynamoDB Stream event source with INSERT filter
        dynamodb_fn.add_event_source(
            lambda_event_sources.DynamoEventSource(
                table,
                starting_position=lambda_.StartingPosition.TRIM_HORIZON,
                batch_size=1,
                filters=[
                    lambda_.FilterCriteria.filter({
                        "eventName": lambda_.FilterRule.is_equal("INSERT"),
                    }),
                ],
            )
        )

        # SQS event source with data:A filter
        sqs_fn.add_event_source(
            lambda_event_sources.SqsEventSource(
                queue,
                batch_size=1,
                filters=[
                    lambda_.FilterCriteria.filter({
                        "body": {
                            "data": lambda_.FilterRule.is_equal("A"),
                        },
                    }),
                ],
            )
        )

        # Outputs
        CfnOutput(self, "TableName", value=table.table_name)
        CfnOutput(self, "StreamArn", value=table.table_stream_arn or "")
        CfnOutput(self, "QueueName", value=queue.queue_name)
        CfnOutput(self, "QueueUrl", value=queue.queue_url)
        CfnOutput(self, "QueueArn", value=queue.queue_arn)
        CfnOutput(self, "DynamoDBFunctionName", value=dynamodb_fn.function_name)
        CfnOutput(self, "SQSFunctionName", value=sqs_fn.function_name)


# Use timestamp suffix for unique stack name
suffix = os.environ.get("RESOURCE_SUFFIX", str(int(__import__("time").time())))
stack_name = f"LambdaEventFilteringStack-{suffix}"

app = cdk.App()
LambdaEventFilteringStack(
    app,
    stack_name,
    env=cdk.Environment(
        account=os.environ.get("CDK_DEFAULT_ACCOUNT", "000000000000"),
        region=os.environ.get("CDK_DEFAULT_REGION", "us-east-1"),
    ),
)
app.synth()
