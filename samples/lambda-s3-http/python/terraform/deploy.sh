#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Deploying Lambda S3 HTTP via Terraform"

cd "$SCRIPT_DIR"

if command -v tflocal &> /dev/null; then
    TF="tflocal"
else
    TF="terraform"
fi

echo "Step 1: Initializing Terraform..."
$TF init -input=false

echo "Step 2: Applying Terraform configuration..."
$TF apply -auto-approve -input=false

echo "Step 3: Extracting outputs..."
TABLE_NAME=$($TF output -raw table_name)
BUCKET_NAME=$($TF output -raw bucket_name)
QUEUE_NAME=$($TF output -raw queue_name)
QUEUE_URL=$($TF output -raw queue_url)
HTTP_FUNCTION=$($TF output -raw http_function)
S3_FUNCTION=$($TF output -raw s3_function)
SQS_FUNCTION=$($TF output -raw sqs_function)

cat > "$SCRIPT_DIR/../scripts/.env" << EOF
TABLE_NAME=$TABLE_NAME
BUCKET_NAME=$BUCKET_NAME
QUEUE_NAME=$QUEUE_NAME
QUEUE_URL=$QUEUE_URL
HTTP_FUNCTION=$HTTP_FUNCTION
S3_FUNCTION=$S3_FUNCTION
SQS_FUNCTION=$SQS_FUNCTION
REGION=us-east-1
EOF

echo ""
echo "Deployment complete!"
echo "  Table: $TABLE_NAME"
echo "  Bucket: $BUCKET_NAME"
echo "  Queue: $QUEUE_NAME"
echo "  HTTP Function: $HTTP_FUNCTION"
echo "  S3 Function: $S3_FUNCTION"
echo "  SQS Function: $SQS_FUNCTION"
