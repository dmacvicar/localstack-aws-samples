#!/usr/bin/env python3
"""Lambda S3 HTTP Sample - CDK Stack."""

import os
import aws_cdk as cdk
from aws_cdk import (
    Stack,
    aws_lambda as lambda_,
    aws_dynamodb as dynamodb,
    aws_s3 as s3,
    aws_sqs as sqs,
    aws_s3_notifications as s3n,
    aws_lambda_event_sources as lambda_events,
    aws_iam as iam,
    CfnOutput,
    Duration,
    RemovalPolicy,
)
from constructs import Construct


class LambdaS3HttpStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        prefix = "cdk"

        # DynamoDB table
        table = dynamodb.Table(
            self, "ScoresTable",
            table_name=f"{prefix}-game-scores",
            partition_key=dynamodb.Attribute(
                name="playerId",
                type=dynamodb.AttributeType.STRING
            ),
            billing_mode=dynamodb.BillingMode.PAY_PER_REQUEST,
            removal_policy=RemovalPolicy.DESTROY,
        )

        # SQS queue
        queue = sqs.Queue(
            self, "ValidationQueue",
            queue_name=f"{prefix}-score-validation",
        )

        # S3 bucket
        bucket = s3.Bucket(
            self, "ReplaysBucket",
            bucket_name=f"{prefix}-replays",
            removal_policy=RemovalPolicy.DESTROY,
            auto_delete_objects=True,
        )

        # HTTP handler code
        http_code = '''
import json
import logging
import os
import boto3
from datetime import datetime
from decimal import Decimal

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ENDPOINT_URL = os.environ.get('LOCALSTACK_HOSTNAME')
if ENDPOINT_URL:
    ENDPOINT_URL = f"http://{ENDPOINT_URL}:4566"
dynamodb = boto3.resource('dynamodb', endpoint_url=ENDPOINT_URL)
sqs = boto3.client('sqs', endpoint_url=ENDPOINT_URL)
TABLE_NAME = os.environ.get('TABLE_NAME')
QUEUE_URL = os.environ.get('QUEUE_URL', '')

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super().default(obj)

def handler(event, context):
    method = event.get('httpMethod', 'GET')
    path = event.get('path', '/')
    path_params = event.get('pathParameters') or {}
    body = event.get('body')
    if body and isinstance(body, str):
        try:
            body = json.loads(body)
        except:
            pass

    if path == '/scores' and method == 'GET':
        return get_top_scores()
    elif path == '/scores' and method == 'POST':
        return submit_score(body)
    elif path.startswith('/scores/') and method == 'GET':
        player_id = path_params.get('playerId') or path.split('/')[-1]
        return get_player_scores(player_id)
    return response(404, {'error': 'Not found'})

def get_top_scores():
    table = dynamodb.Table(TABLE_NAME)
    result = table.scan(Limit=10)
    items = sorted(result.get('Items', []), key=lambda x: x.get('score', 0), reverse=True)
    return response(200, {'scores': items[:10]})

def submit_score(body):
    if not body:
        return response(400, {'error': 'Invalid request body'})
    player_id = body.get('playerId')
    score = body.get('score')
    game = body.get('game', 'default')
    if not player_id or score is None:
        return response(400, {'error': 'playerId and score are required'})
    table = dynamodb.Table(TABLE_NAME)
    item = {'playerId': player_id, 'score': Decimal(str(score)), 'game': game, 'timestamp': datetime.utcnow().isoformat()}
    table.put_item(Item=item)
    if QUEUE_URL:
        sqs.send_message(QueueUrl=QUEUE_URL, MessageBody=json.dumps(item, cls=DecimalEncoder))
    return response(201, {'message': 'Score submitted', 'item': item})

def get_player_scores(player_id):
    table = dynamodb.Table(TABLE_NAME)
    result = table.query(KeyConditionExpression='playerId = :pid', ExpressionAttributeValues={':pid': player_id})
    return response(200, {'playerId': player_id, 'scores': result.get('Items', [])})

def response(status_code, body):
    return {'statusCode': status_code, 'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'}, 'body': json.dumps(body, cls=DecimalEncoder)}
'''

        # S3 handler code
        s3_code = '''
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    logger.info('S3 event: %s', json.dumps(event))
    for record in event.get('Records', []):
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        logger.info('Processing: s3://%s/%s', bucket, key)
    return {'statusCode': 200, 'body': 'OK'}
'''

        # SQS handler code
        sqs_code = '''
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    logger.info('SQS event: %s', json.dumps(event))
    for record in event.get('Records', []):
        body = json.loads(record['body'])
        logger.info('Validating score: %s', body)
    return {'statusCode': 200, 'body': 'OK'}
'''

        # HTTP handler Lambda
        http_fn = lambda_.Function(
            self, "HttpFunction",
            function_name=f"{prefix}-http-handler",
            runtime=lambda_.Runtime.PYTHON_3_12,
            handler="index.handler",
            code=lambda_.Code.from_inline(http_code),
            timeout=Duration.seconds(30),
            memory_size=128,
            environment={
                "TABLE_NAME": table.table_name,
                "QUEUE_URL": queue.queue_url,
            },
        )

        # S3 handler Lambda
        s3_fn = lambda_.Function(
            self, "S3Function",
            function_name=f"{prefix}-s3-handler",
            runtime=lambda_.Runtime.PYTHON_3_12,
            handler="index.handler",
            code=lambda_.Code.from_inline(s3_code),
            timeout=Duration.seconds(30),
            memory_size=128,
            environment={
                "TABLE_NAME": table.table_name,
            },
        )

        # SQS handler Lambda
        sqs_fn = lambda_.Function(
            self, "SqsFunction",
            function_name=f"{prefix}-sqs-handler",
            runtime=lambda_.Runtime.PYTHON_3_12,
            handler="index.handler",
            code=lambda_.Code.from_inline(sqs_code),
            timeout=Duration.seconds(30),
            memory_size=128,
            environment={
                "TABLE_NAME": table.table_name,
            },
        )

        # Grant permissions
        table.grant_read_write_data(http_fn)
        table.grant_read_data(s3_fn)
        table.grant_read_data(sqs_fn)
        queue.grant_send_messages(http_fn)
        bucket.grant_read(s3_fn)

        # Function URL
        http_fn.add_function_url(auth_type=lambda_.FunctionUrlAuthType.NONE)

        # S3 notification
        bucket.add_event_notification(
            s3.EventType.OBJECT_CREATED,
            s3n.LambdaDestination(s3_fn),
        )

        # SQS event source
        sqs_fn.add_event_source(
            lambda_events.SqsEventSource(queue, batch_size=10)
        )

        # Outputs
        CfnOutput(self, "TableNameOutput", value=table.table_name, export_name="TableName")
        CfnOutput(self, "BucketNameOutput", value=bucket.bucket_name, export_name="BucketName")
        CfnOutput(self, "QueueNameOutput", value=queue.queue_name, export_name="QueueName")
        CfnOutput(self, "QueueUrlOutput", value=queue.queue_url, export_name="QueueUrl")
        CfnOutput(self, "HttpFunctionOutput", value=http_fn.function_name, export_name="HttpFunction")
        CfnOutput(self, "S3FunctionOutput", value=s3_fn.function_name, export_name="S3Function")
        CfnOutput(self, "SqsFunctionOutput", value=sqs_fn.function_name, export_name="SqsFunction")


app = cdk.App()
LambdaS3HttpStack(
    app, "LambdaS3HttpStack",
    env=cdk.Environment(
        account=os.environ.get("CDK_DEFAULT_ACCOUNT", "000000000000"),
        region=os.environ.get("CDK_DEFAULT_REGION", "us-east-1"),
    ),
)
app.synth()
