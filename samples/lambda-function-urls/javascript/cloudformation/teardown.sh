#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"

LOCALSTACK_ENDPOINT="${LOCALSTACK_ENDPOINT:-http://localhost.localstack.cloud:4566}"

if [ -f "$SAMPLE_DIR/scripts/.env" ]; then
    source "$SAMPLE_DIR/scripts/.env"

    if [ -n "${STACK_NAME:-}" ]; then
        echo "Deleting CloudFormation stack ${STACK_NAME}..."
        awslocal cloudformation delete-stack \
            --stack-name "$STACK_NAME" \
            --endpoint-url "$LOCALSTACK_ENDPOINT" 2>/dev/null || true
    fi

    rm -f "$SAMPLE_DIR/scripts/.env"
fi

echo "Teardown complete"
