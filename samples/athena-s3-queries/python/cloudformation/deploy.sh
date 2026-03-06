#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"

STACK_NAME="athena-s3-queries"
BUCKET_SUFFIX=$(date +%s)

echo "Creating CloudFormation stack: $STACK_NAME"
awslocal cloudformation create-stack \
    --stack-name "$STACK_NAME" \
    --template-body "file://$SCRIPT_DIR/template.yml" \
    --parameters "ParameterKey=BucketSuffix,ParameterValue=$BUCKET_SUFFIX"

echo "Waiting for stack creation..."
awslocal cloudformation wait stack-create-complete --stack-name "$STACK_NAME"

# Get outputs
BUCKET=$(awslocal cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[?OutputKey==`BucketName`].OutputValue' --output text)
DATABASE=$(awslocal cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[?OutputKey==`DatabaseName`].OutputValue' --output text)
TABLE=$(awslocal cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[?OutputKey==`TableName`].OutputValue' --output text)
S3_OUTPUT=$(awslocal cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[?OutputKey==`S3Output`].OutputValue' --output text)
WORKGROUP=$(awslocal cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[?OutputKey==`WorkgroupName`].OutputValue' --output text)

# Upload test data
echo "Uploading test data to S3..."
awslocal s3 cp "$SAMPLE_DIR/data/data.csv" "s3://$BUCKET/data/data.csv"

# Save configuration for tests
cat > "$SAMPLE_DIR/scripts/.env" << EOF
STACK_NAME=$STACK_NAME
BUCKET=$BUCKET
DATABASE=$DATABASE
TABLE=$TABLE
S3_OUTPUT=$S3_OUTPUT
WORKGROUP=$WORKGROUP
EOF

echo ""
echo "Deployment complete!"
echo "Bucket: $BUCKET"
echo "Database: $DATABASE"
echo "Table: $TABLE"
echo "Workgroup: $WORKGROUP"
