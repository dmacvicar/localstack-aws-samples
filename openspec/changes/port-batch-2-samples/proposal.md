# Proposal: Port Batch 2 Samples + Multi-Deployment Methods

## Summary

1. Port 5 new samples from the original repository
2. Add multi-deployment-method support (Terraform, CloudFormation, CDK) to existing samples
3. Align with localstack-azure-samples patterns

## Part 1: New Samples to Port

| Original | New Location | Services | Complexity |
|----------|--------------|----------|------------|
| lambda-container-image | samples/lambda-container-image/python | Lambda, ECR | Simple |
| mq-broker | samples/mq-broker/python | MQ (ActiveMQ) | Simple |
| rds-db-queries | samples/rds-queries/python | RDS, PostgreSQL | Simple |
| athena-s3-queries | samples/athena-queries/python | Athena, S3 | Medium |
| elb-load-balancing | samples/elb-lambda/javascript | ELB (ALB), Lambda | Medium |

## Part 2: Multi-Deployment Method Support

### Directory Structure

Each sample supports multiple deployment methods:

```
samples/{name}/{language}/
├── scripts/           # AWS CLI / awslocal (imperative)
│   ├── deploy.sh
│   └── test.sh
├── terraform/         # Terraform with tflocal
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── deploy.sh      # Wrapper: terraform init && terraform apply
├── cloudformation/    # Static YAML/JSON templates
│   ├── template.yml
│   └── deploy.sh      # Wrapper: aws cloudformation deploy
├── cdk/               # CDK in parent language (python/typescript)
│   ├── app.py         # or app.ts
│   ├── cdk.json
│   ├── requirements.txt  # or package.json
│   └── deploy.sh      # Wrapper: cdklocal deploy
└── src/               # Shared application code
    └── handler.py     # Lambda handlers, etc.
```

### Deployment Method Characteristics

| Method | Type | Tools | Language |
|--------|------|-------|----------|
| scripts/ | Imperative | awslocal, AWS CLI | Bash |
| terraform/ | Declarative IaC | tflocal, Terraform | HCL |
| cloudformation/ | Declarative IaC | awslocal | YAML/JSON |
| cdk/ | Programmatic IaC | cdklocal, CDK | Python/TypeScript |

### run-samples.sh Updates

```bash
# Four sample arrays
SCRIPT_SAMPLES=(
    "samples/lambda-function-urls/python|scripts/deploy.sh|scripts/test.sh|..."
)

TERRAFORM_SAMPLES=(
    "samples/lambda-function-urls/python/terraform|deploy.sh|../scripts/test.sh|..."
)

CLOUDFORMATION_SAMPLES=(
    "samples/lambda-function-urls/python/cloudformation|deploy.sh|../scripts/test.sh|..."
)

CDK_SAMPLES=(
    "samples/lambda-function-urls/python/cdk|deploy.sh|../scripts/test.sh|..."
)

ALL_SAMPLES=("${SCRIPT_SAMPLES[@]}" "${TERRAFORM_SAMPLES[@]}" "${CLOUDFORMATION_SAMPLES[@]}" "${CDK_SAMPLES[@]}")
```

### Test Sharing

Tests are shared across deployment methods:
- `scripts/test.sh` is the canonical test
- Other methods reference `../scripts/test.sh`
- Tests validate deployed resources, not deployment method

### Priority: Add Methods to Existing Samples

Start with simpler samples to establish patterns:

| Sample | scripts | terraform | cloudformation | cdk |
|--------|---------|-----------|----------------|-----|
| lambda-function-urls/python | ✅ exists | 🎯 add | 🎯 add | 🎯 add |
| lambda-s3-http/python | ✅ exists | 🎯 add | - | - |
| web-app-dynamodb/python | ✅ exists | 🎯 add | - | - |

## Implementation Plan

### Phase 1: Establish Patterns
1. Add Terraform to `lambda-function-urls/python` (simplest Lambda sample)
2. Add CloudFormation to `lambda-function-urls/python`
3. Add CDK (Python) to `lambda-function-urls/python`
4. Update `run-samples.sh` with new arrays

### Phase 2: Port New Samples
Port the 5 new samples with scripts/ only (baseline)

### Phase 3: Expand Coverage
Add Terraform/CloudFormation/CDK to more existing samples

## Tools Required

- **Terraform**: `tflocal` wrapper (from `terraform-local` package)
- **CDK**: `cdklocal` wrapper (from `aws-cdk-local` package)
- **CloudFormation**: Uses standard `awslocal cloudformation`

## CI Updates

GitHub Actions workflow needs:
```yaml
- name: Install Terraform
  uses: hashicorp/setup-terraform@v3

- name: Install tflocal
  run: pip install terraform-local

- name: Install CDK
  run: npm install -g aws-cdk aws-cdk-local
```

## Success Criteria

- All deployment methods produce identical resources
- Shared tests pass regardless of deployment method
- CI matrix includes all deployment methods
- Documentation explains each method
