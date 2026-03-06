#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$SAMPLE_DIR/scripts/.env"

echo "Deploying Lambda Event Filtering sample with Terraform..."

cd "$SCRIPT_DIR"

# Initialize and apply Terraform
terraform init -input=false
terraform apply -auto-approve

# Extract outputs and write to env file
echo "Writing environment file..."
TABLE_NAME=$(terraform output -raw table_name)
QUEUE_NAME=$(terraform output -raw queue_name)
QUEUE_URL=$(terraform output -raw queue_url)
QUEUE_ARN=$(terraform output -raw queue_arn)
STREAM_ARN=$(terraform output -raw stream_arn)
DYNAMODB_FUNCTION_NAME=$(terraform output -raw dynamodb_function_name)
SQS_FUNCTION_NAME=$(terraform output -raw sqs_function_name)
DYNAMODB_EVENT_SOURCE_UUID=$(terraform output -raw dynamodb_event_source_uuid)
SQS_EVENT_SOURCE_UUID=$(terraform output -raw sqs_event_source_uuid)

cat > "$ENV_FILE" <<EOF
TABLE_NAME=$TABLE_NAME
QUEUE_NAME=$QUEUE_NAME
QUEUE_URL=$QUEUE_URL
QUEUE_ARN=$QUEUE_ARN
STREAM_ARN=$STREAM_ARN
DYNAMODB_FUNCTION_NAME=$DYNAMODB_FUNCTION_NAME
SQS_FUNCTION_NAME=$SQS_FUNCTION_NAME
DYNAMODB_EVENT_SOURCE_UUID=$DYNAMODB_EVENT_SOURCE_UUID
SQS_EVENT_SOURCE_UUID=$SQS_EVENT_SOURCE_UUID
EOF

echo "Deployment complete!"
echo "Environment file: $ENV_FILE"
