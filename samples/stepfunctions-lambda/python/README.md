# Step Functions Lambda (Python)

This sample demonstrates AWS Step Functions orchestrating multiple Lambda functions in a parallel workflow pattern.

## Architecture

```
Input: {"adam": "LocalStack", "cole": "Stack"}
                    |
                    v
            +---------------+
            | Parallel State|
            +-------+-------+
                    |
         +----------+----------+
         |                     |
         v                     v
  +-------------+       +-------------+
  | Adam Lambda |       | Cole Lambda |
  | (extracts   |       | (extracts   |
  |  "adam")    |       |  "cole")    |
  +------+------+       +------+------+
         |                     |
         +----------+----------+
                    |
                    v
          +-----------------+
          | Combine Lambda  |
          | (joins results) |
          +--------+--------+
                   |
                   v
Output: "Together Adam and Cole say 'LocalStack Stack'!!"
```

## AWS Services Used

- **AWS Step Functions**: Workflow orchestration
- **AWS Lambda**: Serverless compute (3 functions)
- **AWS IAM**: Execution roles

## What This Sample Demonstrates

1. **Parallel State**: Running multiple branches concurrently
2. **Lambda Integration**: Using Step Functions to invoke Lambda functions
3. **Data Flow**: Passing data between states
4. **State Machine Definition**: Amazon States Language (ASL)

## Prerequisites

- LocalStack Pro running
- AWS CLI or awslocal installed
- jq for JSON parsing

## Deployment

```bash
# Deploy the sample
./scripts/deploy.sh

# Run tests
./scripts/test.sh
```

## Testing

The test script validates:

| Test | Description |
|------|-------------|
| Lambda State | All 3 functions are Active |
| State Machine | State machine is ACTIVE |
| Adam Lambda | Returns extracted 'adam' value |
| Cole Lambda | Returns extracted 'cole' value |
| Combine Lambda | Returns combined message |
| Execution | State machine completes with SUCCEEDED |
| Output | Final output matches expected format |

## Sample Execution

**Input:**
```json
{"adam": "LocalStack", "cole": "Stack"}
```

**Workflow:**
1. Parallel State receives input
2. Adam Lambda extracts and returns: `"LocalStack"`
3. Cole Lambda extracts and returns: `"Stack"`
4. Combine Lambda receives `["LocalStack", "Stack"]`
5. Returns: `"Together Adam and Cole say 'LocalStack Stack'!!"`

## Manual Testing

```bash
# Start an execution
awslocal stepfunctions start-execution \
    --state-machine-arn "$STATE_MACHINE_ARN" \
    --input '{"adam": "Hello", "cole": "World"}'

# Check execution status
awslocal stepfunctions describe-execution \
    --execution-arn "$EXECUTION_ARN"
```

## Cleanup

Resources are automatically cleaned up when LocalStack restarts.
