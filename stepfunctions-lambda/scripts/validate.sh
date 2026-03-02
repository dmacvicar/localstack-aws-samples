#!/bin/bash
set -euo pipefail

# Validate Step Functions Lambda sample deployment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$SCRIPT_DIR/../../bin:$PATH"

echo "=== Validating Step Functions Lambda Sample ==="

# Check Lambda functions exist
for func in adam cole combine; do
    echo "Checking Lambda function '$func' exists..."
    FUNCTION_INFO=$(awslocal lambda get-function --function-name $func 2>/dev/null || echo "")
    if [ -z "$FUNCTION_INFO" ]; then
        echo "ERROR: Lambda function '$func' not found"
        exit 1
    fi

    FUNCTION_STATE=$(echo "$FUNCTION_INFO" | jq -r '.Configuration.State')
    if [ "$FUNCTION_STATE" != "Active" ]; then
        echo "Waiting for function '$func' to become active..."
        awslocal lambda wait function-active-v2 --function-name $func
    fi
    echo "✓ Lambda function '$func' exists and is active"
done

# Check IAM role exists
echo "Checking IAM role 'step-function-lambda' exists..."
ROLE_INFO=$(awslocal iam get-role --role-name step-function-lambda 2>/dev/null || echo "")
if [ -z "$ROLE_INFO" ]; then
    echo "ERROR: IAM role 'step-function-lambda' not found"
    exit 1
fi
echo "✓ IAM role 'step-function-lambda' exists"

echo ""
echo "=== Validation Passed ==="
