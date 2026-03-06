# Chalice REST API

This sample demonstrates the AWS Chalice framework with LocalStack using chalice-local.

## Overview

[AWS Chalice](https://github.com/aws/chalice) is a Python serverless microframework for AWS. This sample shows a simple TODO REST API deployed to LocalStack using [chalice-local](https://github.com/localstack/chalice-local).

## Architecture

```
Chalice App (app.py)
    └── chalice-local deploy
         └── API Gateway + Lambda (LocalStack)
              └── REST API Endpoints
```

## Prerequisites

- LocalStack Pro
- Python 3.10+
- chalice and chalice-local

## Installation

Install Chalice and chalice-local:

```bash
pip install chalice chalice-local
```

Or with uv:

```bash
uv tool install chalice
uv tool install chalice-local
```

## IaC Methods

| Method | Status | Notes |
|--------|--------|-------|
| scripts | Supported | Uses chalice-local |
| terraform | Not applicable | Chalice has its own deployment |
| cloudformation | Not applicable | Chalice generates CloudFormation |
| cdk | Not applicable | Chalice has its own deployment |

## Deployment

```bash
cd samples/chalice-rest-api/python

# Deploy
./scripts/deploy.sh

# Or manually
chalice-local deploy

# Teardown
./scripts/teardown.sh

# Or manually
chalice-local delete
```

## Testing

```bash
# Run all tests
uv run pytest samples/chalice-rest-api/python/ -v
```

Tests will skip if chalice-local is not installed.

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | API info |
| GET | `/health` | Health check |
| GET | `/todo` | List all TODOs |
| GET | `/todo/{id}` | Get TODO by ID |
| POST | `/todo` | Add new TODO |
| PUT | `/todo/{id}` | Replace TODO |
| POST | `/todo/{id}` | Update TODO |
| DELETE | `/todo/{id}` | Delete TODO |
| GET | `/introspect` | Request details |

## Example Usage

After deployment:

```bash
# Get API info
curl $API_URL/

# List TODOs
curl $API_URL/todo

# Add TODO
curl -X POST $API_URL/todo \
    -H "Content-Type: application/json" \
    -d '{"item": "New task"}'

# Get specific TODO
curl $API_URL/todo/1

# Health check
curl $API_URL/health
```

## Resources Created

- API Gateway REST API
- Lambda function(s) for each route
- IAM roles for Lambda execution

## Environment Variables

After deployment, the following variables are written to `scripts/.env`:

- `CHALICE_AVAILABLE`: Whether chalice-local is installed
- `DEPLOY_SUCCESS`: Whether deployment succeeded
- `API_URL`: The deployed API URL

## Project Structure

```
chalice-rest-api/python/
├── app.py              # Chalice application
├── .chalice/
│   └── config.json     # Chalice configuration
├── scripts/
│   ├── deploy.sh
│   └── teardown.sh
└── test_chalice_api.py
```

## License

Apache 2.0
