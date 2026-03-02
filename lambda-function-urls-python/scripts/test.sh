#!/bin/bash
set -euo pipefail

# End-to-end test for Lambda function URL sample

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$SCRIPT_DIR/../../bin:$PATH"

echo "=== Testing Lambda Function URLs Sample ==="

# Get function URL
URL_CONFIG=$(awslocal lambda get-function-url-config --function-name trending 2>/dev/null || echo "")
if [ -z "$URL_CONFIG" ]; then
    echo "ERROR: Function URL configuration not found"
    exit 1
fi

FUNCTION_URL=$(echo "$URL_CONFIG" | jq -r '.FunctionUrl')
echo "Function URL: $FUNCTION_URL"

# Wait for function to be ready
echo "Waiting for Lambda function to be ready..."
awslocal lambda wait function-active-v2 --function-name trending

# Test 1: Invoke via function URL
echo ""
echo "Test 1: Invoking Lambda via Function URL..."
RESPONSE=$(curl -s --max-time 30 "$FUNCTION_URL" || echo "CURL_FAILED")

if [ "$RESPONSE" = "CURL_FAILED" ]; then
    echo "ERROR: Failed to invoke function URL"
    exit 1
fi

echo "Response received: $(echo "$RESPONSE" | head -c 200)..."

# Test 2: Invoke via Lambda API
echo ""
echo "Test 2: Invoking Lambda via AWS API..."
awslocal lambda invoke \
    --function-name trending \
    --payload '{}' \
    /tmp/lambda-response.json

if [ -f /tmp/lambda-response.json ]; then
    echo "Lambda invocation response:"
    cat /tmp/lambda-response.json | head -c 500
    echo ""
    rm -f /tmp/lambda-response.json
else
    echo "ERROR: Lambda invocation failed - no response file"
    exit 1
fi

echo ""
echo "=== All Tests Passed ==="
