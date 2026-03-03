# Spec: lambda-function-urls

## Overview

Lambda Function URLs provide HTTPS endpoints directly on Lambda functions without requiring API Gateway.

## Requirements

### Functional Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-1 | Lambda function created with Python 3.12 runtime | Must |
| FR-2 | Function URL created with NONE auth type | Must |
| FR-3 | Function returns structured JSON response | Must |
| FR-4 | Function processes HTTP method, path, query params | Should |
| FR-5 | Function parses JSON body from POST requests | Should |
| FR-6 | Terraform deployment option available | Should |

### Non-Functional Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| NFR-1 | Tests complete in under 60 seconds | Should |
| NFR-2 | No external dependencies (self-contained) | Must |

## Test Scenarios

### Scenario 1: Lambda Function State
**Given** the deploy script has completed
**When** querying the function state
**Then** the function state should be "Active"

### Scenario 2: Function URL Configuration
**Given** the Lambda function exists
**When** querying the function URL config
**Then** auth type should be "NONE"
**And** function URL should be accessible

### Scenario 3: Direct Lambda Invocation
**Given** the Lambda function is active
**When** invoking with a test payload
**Then** response statusCode should be 200
**And** response should contain expected message

### Scenario 4: HTTP GET via Function URL
**Given** the function URL is configured
**When** sending HTTP GET request
**Then** response should be valid JSON
**And** message should be "Hello from Lambda Function URL!"

### Scenario 5: HTTP POST with JSON Body
**Given** the function URL is configured
**When** sending HTTP POST with JSON body `{"name": "LocalStack"}`
**Then** response should echo the parsed body
**And** name field should be "LocalStack"

## Acceptance Criteria

- [ ] Lambda function deploys successfully
- [ ] Function URL is created and accessible
- [ ] Direct Lambda invocation returns valid response
- [ ] HTTP request to Function URL returns valid response
- [ ] Tests validate actual functionality, not just deployment
- [ ] Terraform deployment option works
