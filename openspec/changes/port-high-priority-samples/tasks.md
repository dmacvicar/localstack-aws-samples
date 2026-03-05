# Tasks: Port High Priority Samples

## What "Porting" Means

Each sample must include:
1. **All 4 IaC methods**: scripts/, terraform/, cloudformation/, cdk/
2. **deploy.sh**: Deploys all resources for that IaC method
3. **teardown.sh**: Cleans up all resources
4. **pytest tests**: In `test_<sample>.py`, parameterized by IaC method
5. **Consistent .env output**: All deploy scripts write to `scripts/.env`

## Completed (Phase 1 - Initial Ports)

These have scripts/ but need other IaC methods:

- [x] `lambda-function-urls/python` - All 4 IaC methods complete
- [x] `stepfunctions-lambda/python` - All 4 IaC methods complete
- [x] `web-app-dynamodb/python` - All 4 IaC methods complete
- [x] `lambda-s3-http/python` - All 4 IaC methods complete
- [x] `lambda-cloudfront/python` - scripts only (needs terraform, cloudformation, cdk)
- [x] `web-app-rds/python` - scripts only (needs terraform, cloudformation, cdk)
- [x] `apigw-custom-domain/python` - scripts only (needs terraform, cloudformation, cdk)
- [x] `ecs-ecr-app/python` - scripts only (needs terraform, cloudformation, cdk)
- [x] `apigw-websockets/javascript` - scripts only (Serverless Framework)
- [x] `lambda-layers/javascript` - scripts only (Serverless Framework)

## Completed (Phase 2 - Full Ports with All IaC Methods)

- [x] `lambda-container-image/python`
  - [x] All 4 IaC methods: scripts, terraform, cloudformation, cdk
  - [x] Each has deploy.sh and teardown.sh
  - [x] pytest tests (6 tests × 4 IaC methods)
  - [x] All tests pass locally

- [x] `lambda-cloudfront/python`
  - [x] All 4 IaC methods: scripts, terraform, cloudformation, cdk
  - [x] Each has deploy.sh and teardown.sh
  - [x] pytest tests (4 tests × 4 IaC methods = 16 tests, 12 pass, 4 skipped for CloudFront distribution)
  - [x] All tests pass locally

- [x] `web-app-rds/python`
  - [x] All 4 IaC methods: scripts, terraform, cloudformation, cdk
  - [x] Each has deploy.sh and teardown.sh
  - [x] All IaC methods create VPC + subnets for RDS consistency
  - [x] pytest tests (7 tests × 4 IaC methods = 28 tests)
  - [x] All tests pass locally

## pytest Infrastructure

- [x] Shared fixtures in `samples/conftest.py`
- [x] AWS client fixtures (Lambda, DynamoDB, S3, SQS, Step Functions, ECS, ECR, etc.)
- [x] tenacity-based wait/retry utilities
- [x] Tests inside sample directories (not separate tests/ dir)
- [x] Dependencies in pyproject.toml (run with `uv run pytest`)
- [x] Shared test support with `-k` filtering for language and IaC method

## CI Infrastructure

- [x] Matrix-based GitHub Actions workflow
- [x] Discovers sample × language × IaC combinations automatically
- [x] Uses `uv` for all Python operations (no pip)
- [x] Pinned awscli-local==0.21 to avoid --s3-endpoint-url bug

## To Do (Priority Order)

1. Add IaC methods + teardown scripts to existing samples:
   - [x] `lambda-cloudfront/python`
   - [x] `web-app-rds/python`
   - [ ] `apigw-custom-domain/python`
   - [ ] `ecs-ecr-app/python`

2. Port more samples from original repo:
   - [ ] `cognito-jwt` (requires SMTP - may skip)
   - [ ] `lambda-event-filtering`
   - [ ] `appsync-graphql-api`
   - [ ] `athena-s3-queries`
   - [ ] `glue-etl-jobs`

## CI Status

11 samples, ~180 pytest tests across all IaC method combinations.
