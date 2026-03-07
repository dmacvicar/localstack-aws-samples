#!/bin/bash
set -euo pipefail

# Chalice REST API CDK deployment script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$SAMPLE_DIR/scripts/.env"
STACK_NAME="ChaliceRestApiStack"

echo "Deploying Chalice REST API with CDK..."

cd "$SCRIPT_DIR"

# Install CDK dependencies
pip install -q -r requirements.txt

# Bootstrap CDK (if needed)
cdklocal bootstrap --quiet 2>/dev/null || true

# Deploy
cdklocal deploy "$STACK_NAME" --require-approval never --outputs-file outputs.json

# Extract outputs
API_ID=$(jq -r ".\"$STACK_NAME\".ApiId" outputs.json)
API_URL=$(jq -r ".\"$STACK_NAME\".ApiUrl" outputs.json)
FUNCTION_NAME=$(jq -r ".\"$STACK_NAME\".FunctionName" outputs.json)

echo ""
echo "Chalice REST API deployed successfully!"
echo "  API ID: $API_ID"
echo "  API URL: $API_URL"
echo "  Function: $FUNCTION_NAME"

# Write environment variables
mkdir -p "$(dirname "$ENV_FILE")"
cat > "$ENV_FILE" << EOF
CHALICE_AVAILABLE=true
DEPLOY_SUCCESS=true
API_URL=$API_URL
API_ID=$API_ID
FUNCTION_NAME=$FUNCTION_NAME
EOF

echo ""
echo "Environment written to $ENV_FILE"
