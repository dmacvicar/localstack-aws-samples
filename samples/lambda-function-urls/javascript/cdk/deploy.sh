#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"

cd "$SCRIPT_DIR"

export SUFFIX="${SUFFIX:-$(date +%s)}"

echo "Bootstrapping CDK (if needed)..."
cdklocal bootstrap --quiet 2>/dev/null || true

echo "Deploying CDK stack..."
cdklocal deploy --require-approval never --outputs-file outputs.json

# Extract outputs
FUNCTION_NAME=$(jq -r '.LambdaFunctionUrlsJsStack.FunctionNameOutput' outputs.json)
FUNCTION_URL=$(jq -r '.LambdaFunctionUrlsJsStack.FunctionUrlOutput' outputs.json)
ROLE_NAME=$(jq -r '.LambdaFunctionUrlsJsStack.RoleNameOutput' outputs.json)

# Save configuration for tests
cat > "$SAMPLE_DIR/scripts/.env" << EOF
FUNCTION_NAME=$FUNCTION_NAME
FUNCTION_URL=$FUNCTION_URL
ROLE_NAME=$ROLE_NAME
EOF

echo ""
echo "Deployment complete!"
echo "Function Name: $FUNCTION_NAME"
echo "Function URL: $FUNCTION_URL"
