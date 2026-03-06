#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

ENDPOINT_URL="${AWS_ENDPOINT_URL:-http://localhost.localstack.cloud:4566}"
REGION="${AWS_DEFAULT_REGION:-us-east-1}"

echo "Tearing down Lambda Event Filtering sample..."

# Load environment file if it exists
if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
fi

# Values must come from env file (unique per deployment)
if [[ -z "${TABLE_NAME:-}" ]]; then
    echo "No .env file found, nothing to teardown"
    exit 0
fi

# Delete event source mappings
echo "Deleting event source mappings..."
if [[ -n "${DYNAMODB_EVENT_SOURCE_UUID:-}" ]]; then
    aws lambda delete-event-source-mapping \
        --endpoint-url "$ENDPOINT_URL" \
        --uuid "$DYNAMODB_EVENT_SOURCE_UUID" \
        --region "$REGION" 2>/dev/null || true
fi

if [[ -n "${SQS_EVENT_SOURCE_UUID:-}" ]]; then
    aws lambda delete-event-source-mapping \
        --endpoint-url "$ENDPOINT_URL" \
        --uuid "$SQS_EVENT_SOURCE_UUID" \
        --region "$REGION" 2>/dev/null || true
fi

# Delete Lambda functions
echo "Deleting Lambda functions..."
aws lambda delete-function \
    --endpoint-url "$ENDPOINT_URL" \
    --function-name "$DYNAMODB_FUNCTION_NAME" \
    --region "$REGION" 2>/dev/null || true

aws lambda delete-function \
    --endpoint-url "$ENDPOINT_URL" \
    --function-name "$SQS_FUNCTION_NAME" \
    --region "$REGION" 2>/dev/null || true

# Delete SQS queue
echo "Deleting SQS queue..."
QUEUE_URL="${QUEUE_URL:-}"
if [[ -z "$QUEUE_URL" ]]; then
    QUEUE_URL=$(aws sqs get-queue-url \
        --endpoint-url "$ENDPOINT_URL" \
        --queue-name "$QUEUE_NAME" \
        --region "$REGION" \
        --query 'QueueUrl' \
        --output text 2>/dev/null || true)
fi

if [[ -n "$QUEUE_URL" ]]; then
    aws sqs delete-queue \
        --endpoint-url "$ENDPOINT_URL" \
        --queue-url "$QUEUE_URL" \
        --region "$REGION" 2>/dev/null || true
fi

# Delete DynamoDB table
echo "Deleting DynamoDB table..."
aws dynamodb delete-table \
    --endpoint-url "$ENDPOINT_URL" \
    --table-name "$TABLE_NAME" \
    --region "$REGION" 2>/dev/null || true

# Detach policies and delete IAM role
echo "Cleaning up IAM role..."
aws iam detach-role-policy \
    --endpoint-url "$ENDPOINT_URL" \
    --role-name "$ROLE_NAME" \
    --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" \
    --region "$REGION" 2>/dev/null || true

aws iam detach-role-policy \
    --endpoint-url "$ENDPOINT_URL" \
    --role-name "$ROLE_NAME" \
    --policy-arn "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess" \
    --region "$REGION" 2>/dev/null || true

aws iam detach-role-policy \
    --endpoint-url "$ENDPOINT_URL" \
    --role-name "$ROLE_NAME" \
    --policy-arn "arn:aws:iam::aws:policy/AmazonSQSFullAccess" \
    --region "$REGION" 2>/dev/null || true

aws iam delete-role \
    --endpoint-url "$ENDPOINT_URL" \
    --role-name "$ROLE_NAME" \
    --region "$REGION" 2>/dev/null || true

# Remove environment file
rm -f "$ENV_FILE"

echo "Teardown complete!"
