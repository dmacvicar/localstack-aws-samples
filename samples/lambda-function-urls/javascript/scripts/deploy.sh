#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"

SUFFIX="${SUFFIX:-$(date +%s)}"
FUNCTION_NAME="lambda-url-js-${SUFFIX}"

LOCALSTACK_ENDPOINT="${LOCALSTACK_ENDPOINT:-http://localhost.localstack.cloud:4566}"

# Create deployment package
echo "Creating deployment package..."
PACKAGE_DIR=$(mktemp -d)
cp "$SAMPLE_DIR/index.js" "$PACKAGE_DIR/"
cd "$PACKAGE_DIR"
zip -r function.zip index.js > /dev/null
cd - > /dev/null

# Create IAM role
echo "Creating IAM role..."
ROLE_NAME="lambda-role-${SUFFIX}"
awslocal iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
    --endpoint-url "$LOCALSTACK_ENDPOINT" > /dev/null 2>&1 || true

ROLE_ARN="arn:aws:iam::000000000000:role/$ROLE_NAME"

# Create Lambda function
echo "Creating Lambda function..."
awslocal lambda create-function \
    --function-name "$FUNCTION_NAME" \
    --runtime nodejs18.x \
    --handler index.handler \
    --role "$ROLE_ARN" \
    --zip-file "fileb://$PACKAGE_DIR/function.zip" \
    --endpoint-url "$LOCALSTACK_ENDPOINT" > /dev/null

# Wait for function to be active
echo "Waiting for function to be active..."
for i in {1..30}; do
    STATE=$(awslocal lambda get-function \
        --function-name "$FUNCTION_NAME" \
        --query 'Configuration.State' \
        --output text \
        --endpoint-url "$LOCALSTACK_ENDPOINT" 2>/dev/null || echo "Pending")
    if [ "$STATE" = "Active" ]; then
        break
    fi
    sleep 1
done

# Create function URL
echo "Creating function URL..."
FUNCTION_URL=$(awslocal lambda create-function-url-config \
    --function-name "$FUNCTION_NAME" \
    --auth-type NONE \
    --query 'FunctionUrl' \
    --output text \
    --endpoint-url "$LOCALSTACK_ENDPOINT")

# Add permission for public access
awslocal lambda add-permission \
    --function-name "$FUNCTION_NAME" \
    --statement-id "FunctionURLAllowPublicAccess" \
    --action "lambda:InvokeFunctionUrl" \
    --principal "*" \
    --function-url-auth-type NONE \
    --endpoint-url "$LOCALSTACK_ENDPOINT" > /dev/null 2>&1 || true

# Cleanup temp files
rm -rf "$PACKAGE_DIR"

# Save configuration for tests
cat > "$SCRIPT_DIR/.env" << EOF
FUNCTION_NAME=$FUNCTION_NAME
FUNCTION_URL=$FUNCTION_URL
ROLE_NAME=$ROLE_NAME
EOF

echo ""
echo "Deployment complete!"
echo "Function Name: $FUNCTION_NAME"
echo "Function URL: $FUNCTION_URL"
