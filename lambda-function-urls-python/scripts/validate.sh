#!/bin/bash
set -euo pipefail

# Validate Lambda function URL sample deployment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$SCRIPT_DIR/../../bin:$PATH"

echo "=== Validating Lambda Function URLs Sample ==="

# Check Lambda function exists
echo "Checking Lambda function 'trending' exists..."
FUNCTION_INFO=$(awslocal lambda get-function --function-name trending 2>/dev/null || echo "")
if [ -z "$FUNCTION_INFO" ]; then
    echo "ERROR: Lambda function 'trending' not found"
    exit 1
fi
echo "✓ Lambda function 'trending' exists"

# Check function state is Active
FUNCTION_STATE=$(echo "$FUNCTION_INFO" | jq -r '.Configuration.State')
if [ "$FUNCTION_STATE" != "Active" ]; then
    echo "ERROR: Lambda function state is '$FUNCTION_STATE', expected 'Active'"
    exit 1
fi
echo "✓ Lambda function state is Active"

# Check function URL config exists
echo "Checking function URL configuration..."
URL_CONFIG=$(awslocal lambda get-function-url-config --function-name trending 2>/dev/null || echo "")
if [ -z "$URL_CONFIG" ]; then
    echo "ERROR: Function URL configuration not found"
    exit 1
fi
echo "✓ Function URL configuration exists"

# Extract and display the function URL
FUNCTION_URL=$(echo "$URL_CONFIG" | jq -r '.FunctionUrl')
echo "✓ Function URL: $FUNCTION_URL"

echo ""
echo "=== Validation Passed ==="
