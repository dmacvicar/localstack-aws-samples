# Tasks: Port Batch 2 Samples + Multi-Deployment Methods

## Phase 1: Establish Multi-Deployment Patterns

Use `lambda-function-urls/python` as the reference implementation.

- [x] Add Terraform support to `lambda-function-urls/python`
  - [x] Create `terraform/main.tf` (Lambda, IAM role, function URL)
  - [x] Create `terraform/variables.tf` and `outputs.tf`
  - [x] Create `terraform/deploy.sh` (tflocal init/apply wrapper)
  - [x] Verify `../scripts/test.sh` passes after Terraform deploy (7/7 tests)
  - [x] Add to `TERRAFORM_SAMPLES` in run-samples.sh

- [x] Add CloudFormation support to `lambda-function-urls/python`
  - [x] Create `cloudformation/template.yml`
  - [x] Create `cloudformation/deploy.sh` (awslocal cloudformation wrapper)
  - [x] Verify `../scripts/test.sh` passes after CloudFormation deploy (7/7 tests)
  - [x] Add to `CLOUDFORMATION_SAMPLES` in run-samples.sh

- [x] Add CDK support to `lambda-function-urls/python`
  - [x] Create `cdk/app.py` (Python CDK stack)
  - [x] Create `cdk/cdk.json` and `cdk/requirements.txt`
  - [x] Create `cdk/deploy.sh` (cdklocal wrapper)
  - [x] Verify `../scripts/test.sh` passes after CDK deploy (7/7 tests)
  - [x] Add to `CDK_SAMPLES` in run-samples.sh

- [x] Update run-samples.sh
  - [x] Add `TERRAFORM_SAMPLES` array
  - [x] Add `CLOUDFORMATION_SAMPLES` array
  - [x] Add `CDK_SAMPLES` array
  - [x] Combine into `ALL_SAMPLES`
  - [x] Fix name generation for nested IaC paths

## Phase 2: Port New Samples (scripts/ only)

- [ ] `lambda-container-image` → `samples/lambda-container-image/python`
  - [ ] Create Dockerfile (Python Lambda base image)
  - [ ] Write src/handler.py
  - [ ] Write scripts/deploy.sh (ECR create, docker build/push, Lambda create)
  - [ ] Write scripts/test.sh
  - [ ] Add to run-samples.sh

- [ ] `mq-broker` → `samples/mq-broker/python`
  - [ ] Write scripts/deploy.sh (MQ broker creation)
  - [ ] Write scripts/test.sh (message send/receive via HTTP API)
  - [ ] Add to run-samples.sh

- [ ] `rds-db-queries` → `samples/rds-queries/python`
  - [ ] Write src/query.py (psycopg2 database operations)
  - [ ] Write scripts/deploy.sh (RDS instance creation)
  - [ ] Write scripts/test.sh (CRUD operations)
  - [ ] Add to run-samples.sh

- [ ] `athena-s3-queries` → `samples/athena-queries/python`
  - [ ] Create data/sample.csv
  - [ ] Create queries/*.sql (create database, tables, query)
  - [ ] Write scripts/deploy.sh (S3 upload, Athena setup)
  - [ ] Write scripts/test.sh (query execution, result validation)
  - [ ] Add to run-samples.sh

- [ ] `elb-load-balancing` → `samples/elb-lambda/javascript`
  - [ ] Write src/handler.js (Lambda handlers for ALB)
  - [ ] Write serverless.yml (ALB + Lambda config)
  - [ ] Write scripts/deploy.sh
  - [ ] Write scripts/test.sh (ALB endpoint test)
  - [ ] Add to run-samples.sh

## Phase 3: Expand Deployment Methods

Add Terraform to more existing samples:

- [ ] Add Terraform to `web-app-dynamodb/python`
- [ ] Add Terraform to `lambda-s3-http/python`
- [ ] Add Terraform to `stepfunctions-lambda/python`

## In Progress

(None)

## Completed

- [x] Phase 1: Multi-deployment patterns for `lambda-function-urls/python`
  - Terraform, CloudFormation, CDK all pass 7/7 tests
  - run-samples.sh updated with new arrays

## CI Status

Phase 1: 4/4 tasks ✅
Phase 2: 0/5 samples
Phase 3: 0/3 samples

Total samples in CI: 13 (10 scripts + 3 IaC methods)
