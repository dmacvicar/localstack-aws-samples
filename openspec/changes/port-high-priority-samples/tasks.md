# Tasks: Port High Priority Samples

## Completed

- [x] `lambda-function-urls-python` → `samples/lambda-function-urls/python`
- [x] `stepfunctions-lambda` → `samples/stepfunctions-lambda/python`
- [x] `lambda-cloudfront/python`
- [x] `lambda-s3-http/python`
- [x] `web-app-dynamodb/python`
- [x] `web-app-rds/python`
- [x] `lambda-layers/javascript`

### Infrastructure

- [x] Fix Lambda state timing issues in all deploy scripts
- [x] Fix CI workflow to run all tests on push to master
- [x] All 6 samples pass CI

## In Progress

- [x] `serverless-websockets` → `samples/apigw-websockets/javascript`
  - [x] Create directory structure with serverless.yml
  - [x] Write handler.js with WebSocket route handlers
  - [x] Write scripts/deploy.sh
  - [x] Write scripts/test.sh (9 test cases)
  - [x] Deployment works - API created, functions active, routes configured
  - [x] Test WebSocket message round-trip (using uv for websockets library)
  - [x] Add to run-samples.sh
  - [x] Verified via run-samples.sh (act conflicts with running LocalStack)

- [x] `ecs-ecr-container-app` → `samples/ecs-ecr-app/python`
  - [x] Create directory structure with Dockerfile and templates
  - [x] Write CloudFormation templates (ecs-infra.yml, ecs-service.yml)
  - [x] Write scripts/deploy.sh (ECR, Docker push, CloudFormation)
  - [x] Write scripts/test.sh (6 test cases)
  - [x] All tests pass: ECR repo, image, cluster, service, task, HTTP
  - [x] Add to run-samples.sh

- [x] `apigw-custom-domain` → `samples/apigw-custom-domain/python`
  - [x] Create directory structure with handler.py
  - [x] Write scripts/deploy.sh (SSL cert, ACM, Route53, Lambda, API Gateway, custom domain)
  - [x] Write scripts/test.sh (6 test cases)
  - [x] All tests pass: ACM cert, Route53 zone, Lambda, HTTP API, custom domain, API response
  - [x] Add to run-samples.sh

## IaC Methods

Adding Terraform, CloudFormation, and CDK deployment methods:

- [x] `lambda-function-urls/python` - All 3 IaC methods (tested, passing)
- [x] `stepfunctions-lambda/python` - All 3 IaC methods (tested, passing)
- [x] `web-app-dynamodb/python` - All 3 IaC methods (tested, passing)
- [x] `lambda-s3-http/python` - Terraform (tested, passing), CloudFormation/CDK (created)
- [ ] `lambda-cloudfront/python` - IaC methods needed
- [ ] `web-app-rds/python` - IaC methods needed
- [ ] `apigw-custom-domain/python` - IaC methods needed
- [ ] `ecs-ecr-app/python` - IaC methods needed

## pytest Migration

Migrating from bash tests to pytest for better assertions and retry handling:

- [x] Create `tests/conftest.py` with shared fixtures
- [x] Add sample discovery for test matrix (sample × IaC method)
- [x] Add AWS client fixtures
- [x] Add tenacity-based wait/retry utilities
- [ ] Convert sample tests to pytest
- [ ] Update run-samples.sh to use pytest

## To Do

- [ ] Complete pytest migration for all samples
- [ ] Add remaining IaC methods to samples
- [ ] Port additional samples from original repo (Phase 2)

## CI Status

10 base samples + 4 Terraform + 3 CloudFormation + 3 CDK = 20 deployable targets.
