#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REGION="${AWS_DEFAULT_REGION:-us-east-1}"

# Use timestamp suffix for unique stack name
export RESOURCE_SUFFIX="${RESOURCE_SUFFIX:-$(date +%s)}"

echo "Deploying Lambda Event Filtering Sample via CDK"

cd "$SCRIPT_DIR"

if command -v cdklocal &> /dev/null; then
    CDK="cdklocal"
else
    CDK="cdk"
fi

AWS="aws --endpoint-url=http://localhost.localstack.cloud:4566"

echo "Step 1: Installing CDK dependencies..."
uv pip install --system -r requirements.txt --quiet 2>/dev/null || true

echo "Step 2: Bootstrapping CDK..."
$CDK bootstrap --quiet 2>/dev/null || true

echo "Step 3: Deploying stack..."
$CDK deploy --require-approval never --outputs-file cdk-outputs.json 2>&1 | tail -10

# Get the stack name from outputs (first key in the JSON)
STACK_NAME=$(jq -r 'keys[0]' cdk-outputs.json)

# Get outputs
TABLE_NAME=$(jq -r ".[\"$STACK_NAME\"].TableName" cdk-outputs.json)
STREAM_ARN=$(jq -r ".[\"$STACK_NAME\"].StreamArn" cdk-outputs.json)
QUEUE_NAME=$(jq -r ".[\"$STACK_NAME\"].QueueName" cdk-outputs.json)
QUEUE_URL=$(jq -r ".[\"$STACK_NAME\"].QueueUrl" cdk-outputs.json)
QUEUE_ARN=$(jq -r ".[\"$STACK_NAME\"].QueueArn" cdk-outputs.json)
DYNAMODB_FUNCTION_NAME=$(jq -r ".[\"$STACK_NAME\"].DynamoDBFunctionName" cdk-outputs.json)
SQS_FUNCTION_NAME=$(jq -r ".[\"$STACK_NAME\"].SQSFunctionName" cdk-outputs.json)

echo "Step 4: Waiting for functions to be active..."
MAX_ATTEMPTS=30
ATTEMPT=1

while [[ $ATTEMPT -le $MAX_ATTEMPTS ]]; do
    STATE1=$($AWS lambda get-function \
        --function-name "$DYNAMODB_FUNCTION_NAME" \
        --region "$REGION" \
        --query 'Configuration.State' \
        --output text 2>/dev/null || echo "Pending")

    STATE2=$($AWS lambda get-function \
        --function-name "$SQS_FUNCTION_NAME" \
        --region "$REGION" \
        --query 'Configuration.State' \
        --output text 2>/dev/null || echo "Pending")

    if [[ "$STATE1" == "Active" && "$STATE2" == "Active" ]]; then
        echo "  Functions are active"
        break
    fi
    echo "  DynamoDB: $STATE1, SQS: $STATE2 (attempt $ATTEMPT/$MAX_ATTEMPTS)"
    sleep 2
    ATTEMPT=$((ATTEMPT + 1))
done

# Save outputs for tests
cat > "$PROJECT_DIR/scripts/.env" << EOF
TABLE_NAME=$TABLE_NAME
QUEUE_NAME=$QUEUE_NAME
QUEUE_URL=$QUEUE_URL
QUEUE_ARN=$QUEUE_ARN
STREAM_ARN=$STREAM_ARN
DYNAMODB_FUNCTION_NAME=$DYNAMODB_FUNCTION_NAME
SQS_FUNCTION_NAME=$SQS_FUNCTION_NAME
STACK_NAME=$STACK_NAME
EOF

echo ""
echo "Deployment complete!"
echo "  Stack: $STACK_NAME"
echo "  Table: $TABLE_NAME"
echo "  Queue: $QUEUE_NAME"
echo "  DynamoDB Function: $DYNAMODB_FUNCTION_NAME"
echo "  SQS Function: $SQS_FUNCTION_NAME"
