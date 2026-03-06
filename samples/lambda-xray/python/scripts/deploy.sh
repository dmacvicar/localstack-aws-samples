#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"

SUFFIX=$(date +%s)
FUNCTION_NAME="xray-demo-${SUFFIX}"
ROLE_NAME="xray-demo-role-${SUFFIX}"
HANDLER_FILE="$SAMPLE_DIR/handler.py"

echo "Creating IAM role: $ROLE_NAME"
ROLE_ARN=$(awslocal iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {"Service": "lambda.amazonaws.com"},
            "Action": "sts:AssumeRole"
        }]
    }' \
    --query 'Role.Arn' --output text)

echo "Attaching policies..."
awslocal iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

awslocal iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"

awslocal iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess"

echo "Creating Lambda deployment package..."
cd "$SAMPLE_DIR"
zip -j /tmp/lambda-xray.zip "$HANDLER_FILE"

echo "Creating Lambda function: $FUNCTION_NAME"
FUNCTION_ARN=$(awslocal lambda create-function \
    --function-name "$FUNCTION_NAME" \
    --runtime python3.11 \
    --handler handler.lambda_handler \
    --role "$ROLE_ARN" \
    --zip-file fileb:///tmp/lambda-xray.zip \
    --timeout 30 \
    --tracing-config Mode=Active \
    --query 'FunctionArn' --output text)

echo "Waiting for function to be active..."
awslocal lambda wait function-active --function-name "$FUNCTION_NAME"

# Clean up temp file
rm -f /tmp/lambda-xray.zip

# Save configuration for tests
cat > "$SCRIPT_DIR/.env" << EOF
FUNCTION_NAME=$FUNCTION_NAME
FUNCTION_ARN=$FUNCTION_ARN
ROLE_NAME=$ROLE_NAME
ROLE_ARN=$ROLE_ARN
EOF

echo ""
echo "Deployment complete!"
echo "Function: $FUNCTION_NAME"
echo "X-Ray Tracing: Active"
