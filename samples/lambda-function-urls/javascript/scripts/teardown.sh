#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LOCALSTACK_ENDPOINT="${LOCALSTACK_ENDPOINT:-http://localhost.localstack.cloud:4566}"

if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"

    echo "Deleting function URL config..."
    awslocal lambda delete-function-url-config \
        --function-name "$FUNCTION_NAME" \
        --endpoint-url "$LOCALSTACK_ENDPOINT" 2>/dev/null || true

    echo "Deleting Lambda function..."
    awslocal lambda delete-function \
        --function-name "$FUNCTION_NAME" \
        --endpoint-url "$LOCALSTACK_ENDPOINT" 2>/dev/null || true

    echo "Deleting IAM role..."
    awslocal iam delete-role \
        --role-name "$ROLE_NAME" \
        --endpoint-url "$LOCALSTACK_ENDPOINT" 2>/dev/null || true

    rm -f "$SCRIPT_DIR/.env"
fi

echo "Teardown complete"
