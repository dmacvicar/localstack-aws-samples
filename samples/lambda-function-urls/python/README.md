# Lambda Function URLs (Python)

This sample demonstrates AWS Lambda Function URLs - HTTPS endpoints directly on Lambda functions without requiring API Gateway.

## Architecture

```
                    +-------------------+
                    |                   |
Client (HTTP) ----> | Lambda Function   | ----> Response
                    | URL (HTTPS)       |
                    |                   |
                    +-------------------+
```

## AWS Services Used

- **AWS Lambda**: Serverless compute
- **Lambda Function URLs**: Built-in HTTPS endpoints

## What This Sample Demonstrates

1. **Lambda Function URLs**: Creating HTTP endpoints directly on Lambda functions
2. **Public Access**: Configuring NONE authentication for public access
3. **Request Handling**: Processing HTTP method, path, query params, and body
4. **JSON Responses**: Returning structured JSON responses

## Prerequisites

- LocalStack Pro running
- AWS CLI or awslocal installed
- jq for JSON parsing

## Deployment

### Using Scripts

```bash
# Deploy the sample
./scripts/deploy.sh

# Run tests
./scripts/test.sh
```

### Using Terraform

```bash
cd terraform
./deploy.sh
```

## Testing

The test script validates:

| Test | Description |
|------|-------------|
| Function State | Lambda function is Active |
| URL Configuration | Function URL created with NONE auth |
| Direct Invocation | `lambda invoke` returns 200 |
| HTTP GET | GET request via Function URL works |
| HTTP POST | POST with JSON body is processed |

## Sample Request/Response

**Request:**
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"name":"LocalStack"}' \
  "$FUNCTION_URL"
```

**Response:**
```json
{
  "message": "Hello from Lambda Function URL!",
  "request": {
    "method": "POST",
    "path": "/",
    "queryParams": {},
    "body": {"name": "LocalStack"}
  },
  "functionName": "local-function-url-xxx"
}
```

## Cleanup

Resources are automatically cleaned up when LocalStack restarts. For manual cleanup:

```bash
awslocal lambda delete-function --function-name $FUNCTION_NAME
awslocal iam delete-role --role-name $ROLE_NAME
```

## Azure Equivalent

This sample is the AWS equivalent of deploying an Azure Function with HTTP trigger.
