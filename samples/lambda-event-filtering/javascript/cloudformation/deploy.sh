#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$SAMPLE_DIR/scripts/.env"

ENDPOINT_URL="${AWS_ENDPOINT_URL:-http://localhost.localstack.cloud:4566}"
REGION="${AWS_DEFAULT_REGION:-us-east-1}"
SUFFIX="${RESOURCE_SUFFIX:-$(date +%s)}"
STACK_NAME="lambda-event-filtering-cfn-${SUFFIX}"

echo "Deploying Lambda Event Filtering sample with CloudFormation..."

cd "$SCRIPT_DIR"

# Deploy CloudFormation stack
aws cloudformation deploy \
    --endpoint-url "$ENDPOINT_URL" \
    --stack-name "$STACK_NAME" \
    --template-file template.yml \
    --capabilities CAPABILITY_NAMED_IAM \
    --region "$REGION"

# Get outputs
echo "Getting stack outputs..."
TABLE_NAME=$(aws cloudformation describe-stacks \
    --endpoint-url "$ENDPOINT_URL" \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='TableName'].OutputValue" \
    --output text \
    --region "$REGION")

STREAM_ARN=$(aws cloudformation describe-stacks \
    --endpoint-url "$ENDPOINT_URL" \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='StreamArn'].OutputValue" \
    --output text \
    --region "$REGION")

QUEUE_NAME=$(aws cloudformation describe-stacks \
    --endpoint-url "$ENDPOINT_URL" \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='QueueName'].OutputValue" \
    --output text \
    --region "$REGION")

QUEUE_URL=$(aws cloudformation describe-stacks \
    --endpoint-url "$ENDPOINT_URL" \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='QueueUrl'].OutputValue" \
    --output text \
    --region "$REGION")

QUEUE_ARN=$(aws cloudformation describe-stacks \
    --endpoint-url "$ENDPOINT_URL" \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='QueueArn'].OutputValue" \
    --output text \
    --region "$REGION")

DYNAMODB_FUNCTION_NAME=$(aws cloudformation describe-stacks \
    --endpoint-url "$ENDPOINT_URL" \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='DynamoDBFunctionName'].OutputValue" \
    --output text \
    --region "$REGION")

SQS_FUNCTION_NAME=$(aws cloudformation describe-stacks \
    --endpoint-url "$ENDPOINT_URL" \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='SQSFunctionName'].OutputValue" \
    --output text \
    --region "$REGION")

# Write environment file
echo "Writing environment file..."
cat > "$ENV_FILE" <<EOF
TABLE_NAME=$TABLE_NAME
QUEUE_NAME=$QUEUE_NAME
QUEUE_URL=$QUEUE_URL
QUEUE_ARN=$QUEUE_ARN
STREAM_ARN=$STREAM_ARN
DYNAMODB_FUNCTION_NAME=$DYNAMODB_FUNCTION_NAME
SQS_FUNCTION_NAME=$SQS_FUNCTION_NAME
STACK_NAME=$STACK_NAME
EOF

echo "Deployment complete!"
echo "Environment file: $ENV_FILE"
