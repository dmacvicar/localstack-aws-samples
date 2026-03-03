"""
Lambda Function URL Handler

Demonstrates Lambda Function URLs - HTTPS endpoints directly on Lambda functions.
Returns information about the incoming request.
"""

import json


def handler(event, context):
    """
    Handle HTTP requests via Lambda Function URL.

    Args:
        event: Request event from Function URL
        context: Lambda context

    Returns:
        HTTP response with request details
    """
    # Extract request details
    http_method = event.get("requestContext", {}).get("http", {}).get("method", "UNKNOWN")
    path = event.get("requestContext", {}).get("http", {}).get("path", "/")
    query_params = event.get("queryStringParameters") or {}
    headers = event.get("headers") or {}

    # Parse body if present
    body = event.get("body")
    if body:
        try:
            body = json.loads(body)
        except (json.JSONDecodeError, TypeError):
            pass  # Keep as string if not JSON

    # Build response
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
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(response_body)
    }
