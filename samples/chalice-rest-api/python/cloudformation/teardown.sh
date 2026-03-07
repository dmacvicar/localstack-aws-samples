#!/bin/bash
set -euo pipefail

# Chalice REST API CloudFormation teardown script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$SAMPLE_DIR/scripts/.env"
STACK_NAME="chalice-rest-api"

echo "Tearing down Chalice REST API CloudFormation resources..."

# Delete stack
awslocal cloudformation delete-stack --stack-name "$STACK_NAME" 2>/dev/null || true

# Wait for deletion
awslocal cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" 2>/dev/null || true

# Clean up
rm -f "$ENV_FILE"

echo "Teardown complete"
