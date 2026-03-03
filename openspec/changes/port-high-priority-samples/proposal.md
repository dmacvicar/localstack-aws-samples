## Why

The `localstack-aws-samples` repository was restructured to match the `localstack-azure-samples` convention. The old `localstack-pro-samples` contained many useful samples that need to be ported to the new structure to provide comprehensive AWS service examples for LocalStack users.

## What Changes

Port high-priority samples from the old repository structure to the new convention:

1. **lambda-function-urls** - Lambda with direct HTTP endpoints (Function URLs)
2. **stepfunctions-lambda** - Step Functions orchestrating Lambda functions
3. **apigw-websockets** - API Gateway V2 WebSocket APIs (blocked - requires API Gateway V2)
4. **lambda-layers** - Lambda Layers for code sharing (in progress - layer loading issues)
5. **apigw-custom-domain** - API Gateway custom domain mapping
6. **ecs-ecr-app** - Containerized app on ECS with ECR

## Capabilities

### New Capabilities

- **lambda-function-urls/python**: Lambda Function URLs with public HTTP access
  - Tests: function creation, URL configuration, direct invocation, HTTP GET/POST
  - Includes Terraform deployment option

- **stepfunctions-lambda/python**: Step Functions parallel workflow
  - Tests: individual Lambda functions, state machine creation, execution flow, output validation

### Modified Capabilities

- **run-samples.sh**: Added new samples to test matrix
- **PORTING.md**: Updated to track porting progress

## Impact

- Expands the sample coverage for LocalStack users
- Demonstrates more AWS service patterns locally
- No impact on existing samples (additive changes only)
