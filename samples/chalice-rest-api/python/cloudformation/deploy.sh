#!/bin/bash
set -euo pipefail

# Chalice REST API CloudFormation deployment script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$SAMPLE_DIR/scripts/.env"
STACK_NAME="chalice-rest-api"
FUNCTION_NAME="todo-api"

echo "Deploying Chalice REST API with CloudFormation..."

cd "$SCRIPT_DIR"

# Create Lambda deployment package
echo "Creating Lambda deployment package..."
DEPLOY_DIR=$(mktemp -d)
cp "$SAMPLE_DIR/handler.py" "$DEPLOY_DIR/"
cd "$DEPLOY_DIR"
zip -q lambda.zip handler.py
cd "$SCRIPT_DIR"

# Upload Lambda code to S3
BUCKET_NAME="chalice-api-deployments-$(date +%s)"
awslocal s3 mb "s3://$BUCKET_NAME"
awslocal s3 cp "$DEPLOY_DIR/lambda.zip" "s3://$BUCKET_NAME/lambda.zip"

# Deploy CloudFormation stack
echo "Deploying CloudFormation stack..."
awslocal cloudformation deploy \
    --stack-name "$STACK_NAME" \
    --template-file template.yml \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides FunctionName="$FUNCTION_NAME" \
    --no-fail-on-empty-changeset

# Update Lambda code (CloudFormation ZipFile is a placeholder)
echo "Updating Lambda function code..."
awslocal lambda update-function-code \
    --function-name "$FUNCTION_NAME" \
    --s3-bucket "$BUCKET_NAME" \
    --s3-key lambda.zip

# Wait for Lambda to be updated
sleep 2

# Get outputs
API_ID=$(awslocal cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='ApiId'].OutputValue" \
    --output text)

LOCALSTACK_ENDPOINT="${LOCALSTACK_ENDPOINT:-http://localhost.localstack.cloud:4566}"
API_URL="${LOCALSTACK_ENDPOINT}/restapis/${API_ID}/api/_user_request_"

# Clean up temp files
rm -rf "$DEPLOY_DIR"
awslocal s3 rm "s3://$BUCKET_NAME/lambda.zip" || true
awslocal s3 rb "s3://$BUCKET_NAME" || true

echo ""
echo "Chalice REST API deployed successfully!"
echo "  Stack: $STACK_NAME"
echo "  API ID: $API_ID"
echo "  API URL: $API_URL"

# Write environment variables
mkdir -p "$(dirname "$ENV_FILE")"
cat > "$ENV_FILE" << EOF
CHALICE_AVAILABLE=true
DEPLOY_SUCCESS=true
API_URL=$API_URL
API_ID=$API_ID
STACK_NAME=$STACK_NAME
FUNCTION_NAME=$FUNCTION_NAME
EOF

echo ""
echo "Environment written to $ENV_FILE"
