import os
import json
import logging
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize Lambda client
lambda_client = boto3.client("lambda")


def lambda_handler(event, context):
    """Lambda function with X-Ray tracing enabled."""
    logger.info(f"Event: {json.dumps(event)}")
    logger.info(f"Request ID: {context.aws_request_id}")

    # Get Lambda account settings (will be traced by X-Ray)
    response = lambda_client.get_account_settings()

    # Return account usage info
    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "X-Ray tracing demo",
            "accountUsage": response.get("AccountUsage", {}),
            "requestId": context.aws_request_id
        })
    }
