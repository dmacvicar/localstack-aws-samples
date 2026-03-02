#!/bin/bash
set -euo pipefail

# End-to-end test for Step Functions Lambda sample

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$SCRIPT_DIR/../../bin:$PATH"

echo "=== Testing Step Functions Lambda Sample ==="

# Test 1: Invoke 'adam' Lambda
echo ""
echo "Test 1: Invoking 'adam' Lambda function..."
ADAM_RESPONSE=$(awslocal lambda invoke \
    --function-name adam \
    --payload '{"name": "test"}' \
    /tmp/adam-response.json 2>&1)

if [ -f /tmp/adam-response.json ]; then
    echo "Adam Lambda response:"
    cat /tmp/adam-response.json
    echo ""
    rm -f /tmp/adam-response.json
else
    echo "ERROR: Adam Lambda invocation failed"
    exit 1
fi

# Test 2: Invoke 'cole' Lambda
echo ""
echo "Test 2: Invoking 'cole' Lambda function..."
COLE_RESPONSE=$(awslocal lambda invoke \
    --function-name cole \
    --payload '{"name": "test"}' \
    /tmp/cole-response.json 2>&1)

if [ -f /tmp/cole-response.json ]; then
    echo "Cole Lambda response:"
    cat /tmp/cole-response.json
    echo ""
    rm -f /tmp/cole-response.json
else
    echo "ERROR: Cole Lambda invocation failed"
    exit 1
fi

# Test 3: Invoke 'combine' Lambda with both inputs
echo ""
echo "Test 3: Invoking 'combine' Lambda function..."
COMBINE_RESPONSE=$(awslocal lambda invoke \
    --function-name combine \
    --payload '{"adam": "Hello from Adam", "cole": "Hello from Cole"}' \
    /tmp/combine-response.json 2>&1)

if [ -f /tmp/combine-response.json ]; then
    echo "Combine Lambda response:"
    cat /tmp/combine-response.json
    echo ""
    rm -f /tmp/combine-response.json
else
    echo "ERROR: Combine Lambda invocation failed"
    exit 1
fi

echo ""
echo "=== All Tests Passed ==="
