#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"

SUFFIX=$(date +%s)
STACK_NAME="lambda-xray-${SUFFIX}"

echo "Creating CloudFormation stack: $STACK_NAME"
awslocal cloudformation create-stack \
    --stack-name "$STACK_NAME" \
    --template-body "file://$SCRIPT_DIR/template.yml" \
    --parameters "ParameterKey=Suffix,ParameterValue=$SUFFIX" \
    --capabilities CAPABILITY_NAMED_IAM

echo "Waiting for stack creation..."
awslocal cloudformation wait stack-create-complete --stack-name "$STACK_NAME"

# Get outputs
FUNCTION_NAME=$(awslocal cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[?OutputKey==`FunctionName`].OutputValue' --output text)
FUNCTION_ARN=$(awslocal cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[?OutputKey==`FunctionArn`].OutputValue' --output text)
ROLE_NAME=$(awslocal cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[?OutputKey==`RoleName`].OutputValue' --output text)
ROLE_ARN=$(awslocal cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[?OutputKey==`RoleArn`].OutputValue' --output text)

# Save configuration for tests
cat > "$SAMPLE_DIR/scripts/.env" << EOF
STACK_NAME=$STACK_NAME
FUNCTION_NAME=$FUNCTION_NAME
FUNCTION_ARN=$FUNCTION_ARN
ROLE_NAME=$ROLE_NAME
ROLE_ARN=$ROLE_ARN
EOF

echo ""
echo "Deployment complete!"
echo "Function: $FUNCTION_NAME"
echo "X-Ray Tracing: Active"
