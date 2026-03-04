#!/usr/bin/env python3
"""Web App DynamoDB Sample - CDK Stack."""

import os
import aws_cdk as cdk
from aws_cdk import (
    Stack,
    aws_lambda as lambda_,
    aws_dynamodb as dynamodb,
    aws_iam as iam,
    CfnOutput,
    Duration,
    RemovalPolicy,
)
from constructs import Construct


class WebAppDynamoDBStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # DynamoDB Table
        table = dynamodb.Table(
            self, "ItemsTable",
            table_name="cdk-items",
            partition_key=dynamodb.Attribute(
                name="id",
                type=dynamodb.AttributeType.STRING
            ),
            billing_mode=dynamodb.BillingMode.PAY_PER_REQUEST,
            removal_policy=RemovalPolicy.DESTROY,
        )

        # Lambda handler code - must match src/app.py event format
        handler_code = '''
import json
import os
import boto3
from datetime import datetime
from decimal import Decimal

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super().default(obj)

ENDPOINT_URL = os.environ.get('LOCALSTACK_HOSTNAME')
if ENDPOINT_URL:
    ENDPOINT_URL = f"http://{ENDPOINT_URL}:4566"
dynamodb = boto3.resource('dynamodb', endpoint_url=ENDPOINT_URL)
TABLE_NAME = os.environ['TABLE_NAME']

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

    table = dynamodb.Table(TABLE_NAME)

    if path == '/items' and method == 'GET':
        result = table.scan()
        return response(200, {'items': result.get('Items', [])})
    elif path == '/items' and method == 'POST':
        if not body:
            return response(400, {'error': 'Invalid request body'})
        item_id = body.get('id') or f"item-{datetime.utcnow().strftime('%Y%m%d%H%M%S%f')}"
        item = {'id': item_id, 'name': body.get('name', ''), 'description': body.get('description', ''),
                'category': body.get('category', 'general'), 'price': Decimal(str(body.get('price', 0))),
                'createdAt': datetime.utcnow().isoformat(), 'updatedAt': datetime.utcnow().isoformat()}
        table.put_item(Item=item)
        return response(201, item)
    elif path.startswith('/items/') and method == 'GET':
        item_id = path_params.get('id') or path.split('/')[-1]
        result = table.get_item(Key={'id': item_id})
        item = result.get('Item')
        if not item:
            return response(404, {'error': f'Item {item_id} not found'})
        return response(200, item)
    elif path.startswith('/items/') and method == 'PUT':
        item_id = path_params.get('id') or path.split('/')[-1]
        result = table.get_item(Key={'id': item_id})
        if 'Item' not in result:
            return response(404, {'error': f'Item {item_id} not found'})
        update_expr = 'SET updatedAt = :ua'
        expr_values = {':ua': datetime.utcnow().isoformat()}
        expr_names = {}
        if 'name' in body:
            update_expr += ', #n = :n'
            expr_values[':n'] = body['name']
            expr_names['#n'] = 'name'
        if 'price' in body:
            update_expr += ', price = :p'
            expr_values[':p'] = Decimal(str(body['price']))
        update_args = {'Key': {'id': item_id}, 'UpdateExpression': update_expr,
                       'ExpressionAttributeValues': expr_values, 'ReturnValues': 'ALL_NEW'}
        if expr_names:
            update_args['ExpressionAttributeNames'] = expr_names
        result = table.update_item(**update_args)
        return response(200, result.get('Attributes'))
    elif path.startswith('/items/') and method == 'DELETE':
        item_id = path_params.get('id') or path.split('/')[-1]
        result = table.get_item(Key={'id': item_id})
        if 'Item' not in result:
            return response(404, {'error': f'Item {item_id} not found'})
        table.delete_item(Key={'id': item_id})
        return response(204, None)
    return response(404, {'error': 'Not found'})

def response(status_code, body):
    resp = {'statusCode': status_code, 'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'}}
    if body is not None:
        resp['body'] = json.dumps(body, cls=DecimalEncoder)
    return resp
'''

        # Lambda function
        fn = lambda_.Function(
            self, "Handler",
            function_name="cdk-webapp-dynamodb",
            runtime=lambda_.Runtime.PYTHON_3_12,
            handler="index.handler",
            code=lambda_.Code.from_inline(handler_code),
            timeout=Duration.seconds(30),
            memory_size=128,
            environment={
                "TABLE_NAME": table.table_name,
            },
        )

        # Grant DynamoDB access
        table.grant_read_write_data(fn)

        # Function URL
        fn_url = fn.add_function_url(
            auth_type=lambda_.FunctionUrlAuthType.NONE,
        )

        # Outputs
        CfnOutput(self, "FunctionName", value=fn.function_name)
        CfnOutput(self, "FunctionUrl", value=fn_url.url)
        CfnOutput(self, "TableName", value=table.table_name)


app = cdk.App()
WebAppDynamoDBStack(
    app, "WebAppDynamoDBStack",
    env=cdk.Environment(
        account=os.environ.get("CDK_DEFAULT_ACCOUNT", "000000000000"),
        region=os.environ.get("CDK_DEFAULT_REGION", "us-east-1"),
    ),
)
app.synth()
