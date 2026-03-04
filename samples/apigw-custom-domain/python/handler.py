"""Lambda handlers for API Gateway custom domain sample."""

import json


def hello(event, context):
    """Handle /hello endpoint."""
    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Hello from custom domain!"})
    }


def goodbye(event, context):
    """Handle /goodbye endpoint."""
    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Goodbye from custom domain!"})
    }
