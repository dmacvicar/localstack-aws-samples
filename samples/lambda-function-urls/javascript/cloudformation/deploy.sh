#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"

SUFFIX="${SUFFIX:-$(date +%s)}"
STACK_NAME="lambda-url-js-${SUFFIX}"

LOCALSTACK_ENDPOINT="${LOCALSTACK_ENDPOINT:-http://localhost.localstack.cloud:4566}"

echo "Deploying CloudFormation stack..."
awslocal cloudformation deploy \
    --stack-name "$STACK_NAME" \
    --template-file "$SCRIPT_DIR/template.yml" \
    --parameter-overrides "Suffix=$SUFFIX" \
    --capabilities CAPABILITY_NAMED_IAM \
    --endpoint-url "$LOCALSTACK_ENDPOINT"

# Extract outputs
FUNCTION_NAME=$(awslocal cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='FunctionName'].OutputValue" \
    --output text \
    --endpoint-url "$LOCALSTACK_ENDPOINT")

FUNCTION_URL=$(awslocal cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='FunctionUrl'].OutputValue" \
    --output text \
    --endpoint-url "$LOCALSTACK_ENDPOINT")

ROLE_NAME=$(awslocal cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='RoleName'].OutputValue" \
    --output text \
    --endpoint-url "$LOCALSTACK_ENDPOINT")

# Save configuration for tests
cat > "$SAMPLE_DIR/scripts/.env" << EOF
FUNCTION_NAME=$FUNCTION_NAME
FUNCTION_URL=$FUNCTION_URL
ROLE_NAME=$ROLE_NAME
STACK_NAME=$STACK_NAME
EOF

echo ""
echo "Deployment complete!"
echo "Function Name: $FUNCTION_NAME"
echo "Function URL: $FUNCTION_URL"
