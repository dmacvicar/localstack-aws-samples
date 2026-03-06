#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$SAMPLE_DIR/scripts/.env"

ENDPOINT_URL="${AWS_ENDPOINT_URL:-http://localhost.localstack.cloud:4566}"
REGION="${AWS_DEFAULT_REGION:-us-east-1}"
STACK_NAME="lambda-event-filtering-stack"

echo "Tearing down Lambda Event Filtering sample with CloudFormation..."

# Delete CloudFormation stack
aws cloudformation delete-stack \
    --endpoint-url "$ENDPOINT_URL" \
    --stack-name "$STACK_NAME" \
    --region "$REGION" 2>/dev/null || true

# Wait for stack deletion
echo "Waiting for stack deletion..."
aws cloudformation wait stack-delete-complete \
    --endpoint-url "$ENDPOINT_URL" \
    --stack-name "$STACK_NAME" \
    --region "$REGION" 2>/dev/null || true

# Clean up
rm -f "$ENV_FILE"

echo "Teardown complete!"
