"""
Lambda handler for Chalice REST API sample (non-Chalice deployments).

This handler replicates the Chalice app functionality for use with
standard Lambda + API Gateway deployments (Terraform, CloudFormation, CDK).
"""

import json

# In-memory TODO storage
TODO_ITEMS = {
    "1": {"item": "Run LocalStack in detached mode"},
    "2": {"item": "Run your Chalice REST API with LocalStack"},
}


def handler(event, context):
    """Lambda handler for API Gateway proxy integration."""
    http_method = event.get("httpMethod", "GET")
    path = event.get("path", "/")
    query_params = event.get("queryStringParameters") or {}
    path_params = event.get("pathParameters") or {}
    body = event.get("body")

    if body:
        try:
            body = json.loads(body)
        except (json.JSONDecodeError, TypeError):
            body = {}

    # Route handling
    if path == "/" and http_method == "GET":
        return response(200, {"localstack": "chalice integration"})

    elif path == "/health" and http_method == "GET":
        return response(200, "ok\n", content_type="text/plain")

    elif path == "/todo" and http_method == "GET":
        items = list(TODO_ITEMS.values())
        if query_params:
            offset = int(query_params.get("offset", 0))
            size = int(query_params.get("size", len(TODO_ITEMS)))
            items = items[offset:size]
        return response(200, items)

    elif path == "/todo" and http_method == "POST":
        if body:
            new_id = str(len(TODO_ITEMS) + 1)
            TODO_ITEMS[new_id] = body
            return response(200, body)
        return response(400, {"error": "No body provided"})

    elif path.startswith("/todo/") and http_method == "GET":
        todo_id = path_params.get("todo_id") or path.split("/")[-1]
        if todo_id in TODO_ITEMS:
            return response(200, TODO_ITEMS[todo_id])
        return response(404, {"error": "Not found"})

    elif path.startswith("/todo/") and http_method in ("POST", "PUT"):
        todo_id = path_params.get("todo_id") or path.split("/")[-1]
        if todo_id not in TODO_ITEMS:
            TODO_ITEMS[todo_id] = {}
        if http_method == "POST":
            TODO_ITEMS[todo_id].update(body or {})
        else:
            TODO_ITEMS[todo_id] = body or {}
        return response(200, TODO_ITEMS[todo_id])

    elif path.startswith("/todo/") and http_method == "DELETE":
        todo_id = path_params.get("todo_id") or path.split("/")[-1]
        if todo_id in TODO_ITEMS:
            item = TODO_ITEMS[todo_id]
            del TODO_ITEMS[todo_id]
            return response(200, item)
        return response(404, {"error": "Not found"})

    elif path == "/introspect" and http_method == "GET":
        return response(200, {
            "method": http_method,
            "path": path,
            "query_params": query_params,
            "headers": event.get("headers", {}),
        })

    return response(404, {"error": "Not found"})


def response(status_code, body, content_type="application/json"):
    """Create API Gateway response."""
    if content_type == "application/json":
        body = json.dumps(body)
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": content_type,
            "Access-Control-Allow-Origin": "*",
        },
        "body": body,
    }
