#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"

cd "$SCRIPT_DIR"

# CDK dependencies (aws-cdk-lib, constructs) should be installed via project dependencies
# If running standalone: pip install -r requirements.txt

echo "Bootstrapping CDK (if needed)..."
cdklocal bootstrap --quiet 2>/dev/null || true

echo "Deploying CDK stack..."
cdklocal deploy --require-approval never --outputs-file outputs.json

# Extract outputs
FUNCTION_NAME=$(jq -r '.LambdaXRayStack.FunctionName' outputs.json)
FUNCTION_ARN=$(jq -r '.LambdaXRayStack.FunctionArn' outputs.json)
ROLE_NAME=$(jq -r '.LambdaXRayStack.RoleName' outputs.json)
ROLE_ARN=$(jq -r '.LambdaXRayStack.RoleArn' outputs.json)

# Save configuration for tests
cat > "$SAMPLE_DIR/scripts/.env" << EOF
FUNCTION_NAME=$FUNCTION_NAME
FUNCTION_ARN=$FUNCTION_ARN
ROLE_NAME=$ROLE_NAME
ROLE_ARN=$ROLE_ARN
EOF

echo ""
echo "Deployment complete!"
echo "Function: $FUNCTION_NAME"
echo "X-Ray Tracing: Active"
