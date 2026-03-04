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

## To Do

(All samples completed!)

## CI Status

10 samples completed. All pass via `run-samples.sh`.
