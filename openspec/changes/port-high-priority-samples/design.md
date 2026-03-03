# Design: Port High Priority Samples

## Technical Approach

### Directory Structure

Each sample follows the new convention:
```
samples/{sample-name}/{language}/
├── README.md              # Documentation with architecture
├── scripts/
│   ├── deploy.sh         # AWS CLI deployment
│   ├── test.sh           # Comprehensive tests
│   └── .env              # Generated config (gitignored)
├── terraform/            # Optional IaC
│   ├── deploy.sh
│   ├── main.tf
│   ├── providers.tf
│   ├── variables.tf
│   └── outputs.tf
└── src/
    └── *.py              # Application code
```

### Deployment Pattern

1. **scripts/deploy.sh**:
   - Uses `awslocal` if available, fallback to `aws --endpoint-url`
   - Creates IAM roles for Lambda execution
   - Packages and deploys Lambda functions
   - Saves config to `.env` for test script

2. **scripts/test.sh**:
   - Loads config from `.env`
   - Validates deployment (resource existence)
   - Tests actual functionality (not just "is it up")
   - Returns clear pass/fail with summary

### Test Strategy

Tests must validate **functionality**, not just deployment:

| Sample | What to Test |
|--------|--------------|
| lambda-function-urls | HTTP invocation returns correct response |
| stepfunctions-lambda | Execution output matches expected format |
| lambda-layers | Layer code is importable and works |
| apigw-websockets | WebSocket messages are echoed |
| ecs-ecr-app | Container responds to HTTP requests |

### Error Handling

- Scripts use `set -euo pipefail` for strict error handling
- Test scripts return exit code 1 on any failure
- Failures are clearly reported with context

## Implementation Decisions

### Decision 1: awslocal vs AWS CLI
**Choice**: Use awslocal if available, fallback to AWS CLI with endpoint
**Rationale**: Better user experience while maintaining compatibility

### Decision 2: Test Output Format
**Choice**: Simple PASS/FAIL with summary count
**Rationale**: Clear, parseable output for CI integration

### Decision 3: Configuration Persistence
**Choice**: Save to `.env` file between deploy and test
**Rationale**: Allows running test.sh independently after deploy.sh

### Decision 4: Lambda Payload Format
**Choice**: Use `file:///tmp/payload.json` instead of inline JSON
**Rationale**: Avoids base64 encoding issues with awslocal

## Dependencies

- LocalStack Pro (running on localhost:4566)
- AWS CLI or awslocal
- jq for JSON parsing
- zip for packaging Lambda functions
- curl for HTTP testing

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| LocalStack version differences | Test against latest LocalStack Pro |
| API Gateway V2 not in license | Skip apigw-websockets, note in docs |
| Lambda layers not loading | Investigate /opt/python path issue |
