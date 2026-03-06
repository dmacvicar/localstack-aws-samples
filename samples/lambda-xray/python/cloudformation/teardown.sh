#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"

if [ -f "$SAMPLE_DIR/scripts/.env" ]; then
    source "$SAMPLE_DIR/scripts/.env"
fi

STACK_NAME="${STACK_NAME:-lambda-xray}"

echo "Deleting CloudFormation stack: $STACK_NAME"
awslocal cloudformation delete-stack --stack-name "$STACK_NAME" 2>/dev/null || true
awslocal cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" 2>/dev/null || true

rm -f "$SAMPLE_DIR/scripts/.env"
echo "Teardown complete"
