#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

if [ -n "${FUNCTION_NAME:-}" ]; then
    echo "Deleting Lambda function: $FUNCTION_NAME"
    awslocal lambda delete-function --function-name "$FUNCTION_NAME" 2>/dev/null || true
fi

if [ -n "${ROLE_NAME:-}" ]; then
    echo "Detaching policies from role..."
    awslocal iam detach-role-policy --role-name "$ROLE_NAME" \
        --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" 2>/dev/null || true
    awslocal iam detach-role-policy --role-name "$ROLE_NAME" \
        --policy-arn "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess" 2>/dev/null || true
    awslocal iam detach-role-policy --role-name "$ROLE_NAME" \
        --policy-arn "arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess" 2>/dev/null || true

    echo "Deleting IAM role: $ROLE_NAME"
    awslocal iam delete-role --role-name "$ROLE_NAME" 2>/dev/null || true
fi

rm -f "$SCRIPT_DIR/.env"
echo "Teardown complete"
