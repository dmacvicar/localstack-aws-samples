#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$SCRIPT_DIR/.env"

ENDPOINT_URL="${AWS_ENDPOINT_URL:-http://localhost.localstack.cloud:4566}"
REGION="${AWS_DEFAULT_REGION:-us-east-1}"

# Resource names - use timestamp suffix for uniqueness
SUFFIX="${RESOURCE_SUFFIX:-$(date +%s)}"
TABLE_NAME="lambda-event-filtering-table-${SUFFIX}"
QUEUE_NAME="lambda-event-filtering-queue-${SUFFIX}"
DYNAMODB_FUNCTION_NAME="lambda-event-filtering-dynamodb-${SUFFIX}"
SQS_FUNCTION_NAME="lambda-event-filtering-sqs-${SUFFIX}"
ROLE_NAME="lambda-event-filtering-role-${SUFFIX}"

echo "Deploying Lambda Event Filtering sample..."

# Check if table exists and has valid stream
create_table() {
    aws dynamodb create-table \
        --endpoint-url "$ENDPOINT_URL" \
        --table-name "$TABLE_NAME" \
        --attribute-definitions AttributeName=id,AttributeType=S \
        --key-schema AttributeName=id,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --stream-specification StreamEnabled=true,StreamViewType=NEW_IMAGE \
        --region "$REGION" \
        --output json > /dev/null

    echo "Waiting for table to be active..."
    aws dynamodb wait table-exists \
        --endpoint-url "$ENDPOINT_URL" \
        --table-name "$TABLE_NAME" \
        --region "$REGION"
}

echo "Creating DynamoDB table with streams..."
if aws dynamodb describe-table --endpoint-url "$ENDPOINT_URL" --table-name "$TABLE_NAME" --region "$REGION" &>/dev/null; then
    # Table exists - check if stream is valid
    STREAM_ARN=$(aws dynamodb describe-table \
        --endpoint-url "$ENDPOINT_URL" \
        --table-name "$TABLE_NAME" \
        --region "$REGION" \
        --query 'Table.LatestStreamArn' \
        --output text)

    if ! aws dynamodbstreams describe-stream --endpoint-url "$ENDPOINT_URL" --stream-arn "$STREAM_ARN" --region "$REGION" &>/dev/null; then
        echo "  Table exists but stream is stale, recreating..."
        aws dynamodb delete-table --endpoint-url "$ENDPOINT_URL" --table-name "$TABLE_NAME" --region "$REGION" >/dev/null 2>&1 || true
        # Wait for delete to complete
        for i in {1..30}; do
            if ! aws dynamodb describe-table --endpoint-url "$ENDPOINT_URL" --table-name "$TABLE_NAME" --region "$REGION" &>/dev/null; then
                break
            fi
            sleep 1
        done
        create_table
    else
        echo "  Table already exists with valid stream"
    fi
else
    create_table
fi

# Get stream ARN
STREAM_ARN=$(aws dynamodb describe-table \
    --endpoint-url "$ENDPOINT_URL" \
    --table-name "$TABLE_NAME" \
    --region "$REGION" \
    --query 'Table.LatestStreamArn' \
    --output text)

echo "DynamoDB Stream ARN: $STREAM_ARN"

# Create SQS queue (idempotent - create-queue returns existing queue URL)
echo "Creating SQS queue..."
QUEUE_URL=$(aws sqs create-queue \
    --endpoint-url "$ENDPOINT_URL" \
    --queue-name "$QUEUE_NAME" \
    --region "$REGION" \
    --query 'QueueUrl' \
    --output text)

echo "Queue URL: $QUEUE_URL"

# Get queue ARN
QUEUE_ARN=$(aws sqs get-queue-attributes \
    --endpoint-url "$ENDPOINT_URL" \
    --queue-url "$QUEUE_URL" \
    --attribute-names QueueArn \
    --region "$REGION" \
    --query 'Attributes.QueueArn' \
    --output text)

echo "Queue ARN: $QUEUE_ARN"

# Create IAM role for Lambda (idempotent)
echo "Creating IAM role..."
TRUST_POLICY='{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Principal": {"Service": "lambda.amazonaws.com"},
        "Action": "sts:AssumeRole"
    }]
}'

aws iam create-role \
    --endpoint-url "$ENDPOINT_URL" \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document "$TRUST_POLICY" \
    --region "$REGION" \
    --output json > /dev/null 2>&1 || true

ROLE_ARN=$(aws iam get-role \
    --endpoint-url "$ENDPOINT_URL" \
    --role-name "$ROLE_NAME" \
    --region "$REGION" \
    --query 'Role.Arn' \
    --output text)

# Attach policies (idempotent)
aws iam attach-role-policy \
    --endpoint-url "$ENDPOINT_URL" \
    --role-name "$ROLE_NAME" \
    --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" \
    --region "$REGION" 2>/dev/null || true

aws iam attach-role-policy \
    --endpoint-url "$ENDPOINT_URL" \
    --role-name "$ROLE_NAME" \
    --policy-arn "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess" \
    --region "$REGION" 2>/dev/null || true

aws iam attach-role-policy \
    --endpoint-url "$ENDPOINT_URL" \
    --role-name "$ROLE_NAME" \
    --policy-arn "arn:aws:iam::aws:policy/AmazonSQSFullAccess" \
    --region "$REGION" 2>/dev/null || true

# Create deployment package
echo "Creating Lambda deployment package..."
TEMP_DIR=$(mktemp -d)
cp "$SAMPLE_DIR/handler.js" "$TEMP_DIR/"
(cd "$TEMP_DIR" && zip -q handler.zip handler.js)

# Create or update DynamoDB Stream Lambda function
echo "Creating DynamoDB Stream Lambda function..."
if aws lambda get-function --endpoint-url "$ENDPOINT_URL" --function-name "$DYNAMODB_FUNCTION_NAME" --region "$REGION" &>/dev/null; then
    aws lambda update-function-code \
        --endpoint-url "$ENDPOINT_URL" \
        --function-name "$DYNAMODB_FUNCTION_NAME" \
        --zip-file "fileb://$TEMP_DIR/handler.zip" \
        --region "$REGION" \
        --output json > /dev/null
else
    aws lambda create-function \
        --endpoint-url "$ENDPOINT_URL" \
        --function-name "$DYNAMODB_FUNCTION_NAME" \
        --runtime nodejs18.x \
        --handler handler.processDynamoDBStream \
        --role "$ROLE_ARN" \
        --zip-file "fileb://$TEMP_DIR/handler.zip" \
        --region "$REGION" \
        --output json > /dev/null
fi

# Create or update SQS Lambda function
echo "Creating SQS Lambda function..."
if aws lambda get-function --endpoint-url "$ENDPOINT_URL" --function-name "$SQS_FUNCTION_NAME" --region "$REGION" &>/dev/null; then
    aws lambda update-function-code \
        --endpoint-url "$ENDPOINT_URL" \
        --function-name "$SQS_FUNCTION_NAME" \
        --zip-file "fileb://$TEMP_DIR/handler.zip" \
        --region "$REGION" \
        --output json > /dev/null
else
    aws lambda create-function \
        --endpoint-url "$ENDPOINT_URL" \
        --function-name "$SQS_FUNCTION_NAME" \
        --runtime nodejs18.x \
        --handler handler.processSQS \
        --role "$ROLE_ARN" \
        --zip-file "fileb://$TEMP_DIR/handler.zip" \
        --region "$REGION" \
        --output json > /dev/null
fi

# Get or create DynamoDB Stream event source mapping with filter
echo "Creating DynamoDB Stream event source mapping with INSERT filter..."
EXISTING_DYNAMODB_ESM=$(aws lambda list-event-source-mappings \
    --endpoint-url "$ENDPOINT_URL" \
    --function-name "$DYNAMODB_FUNCTION_NAME" \
    --region "$REGION" \
    --query 'EventSourceMappings[0].UUID' \
    --output text 2>/dev/null || echo "None")

if [[ "$EXISTING_DYNAMODB_ESM" == "None" || -z "$EXISTING_DYNAMODB_ESM" ]]; then
    DYNAMODB_EVENT_SOURCE_UUID=$(aws lambda create-event-source-mapping \
        --endpoint-url "$ENDPOINT_URL" \
        --function-name "$DYNAMODB_FUNCTION_NAME" \
        --event-source-arn "$STREAM_ARN" \
        --batch-size 1 \
        --starting-position TRIM_HORIZON \
        --filter-criteria '{"Filters": [{"Pattern": "{\"eventName\": [\"INSERT\"]}"}]}' \
        --region "$REGION" \
        --query 'UUID' \
        --output text)
else
    DYNAMODB_EVENT_SOURCE_UUID="$EXISTING_DYNAMODB_ESM"
    echo "  Event source mapping already exists: $DYNAMODB_EVENT_SOURCE_UUID"
fi

echo "DynamoDB Event Source Mapping UUID: $DYNAMODB_EVENT_SOURCE_UUID"

# Get or create SQS event source mapping with filter
echo "Creating SQS event source mapping with data:A filter..."
EXISTING_SQS_ESM=$(aws lambda list-event-source-mappings \
    --endpoint-url "$ENDPOINT_URL" \
    --function-name "$SQS_FUNCTION_NAME" \
    --region "$REGION" \
    --query 'EventSourceMappings[0].UUID' \
    --output text 2>/dev/null || echo "None")

if [[ "$EXISTING_SQS_ESM" == "None" || -z "$EXISTING_SQS_ESM" ]]; then
    SQS_EVENT_SOURCE_UUID=$(aws lambda create-event-source-mapping \
        --endpoint-url "$ENDPOINT_URL" \
        --function-name "$SQS_FUNCTION_NAME" \
        --event-source-arn "$QUEUE_ARN" \
        --batch-size 1 \
        --filter-criteria '{"Filters": [{"Pattern": "{\"body\": {\"data\": [\"A\"]}}"}]}' \
        --region "$REGION" \
        --query 'UUID' \
        --output text)
else
    SQS_EVENT_SOURCE_UUID="$EXISTING_SQS_ESM"
    echo "  Event source mapping already exists: $SQS_EVENT_SOURCE_UUID"
fi

echo "SQS Event Source Mapping UUID: $SQS_EVENT_SOURCE_UUID"

# Cleanup temp directory
rm -rf "$TEMP_DIR"

# Write environment file
echo "Writing environment file..."
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
ROLE_NAME=$ROLE_NAME
EOF

echo "Deployment complete!"
echo "Environment file: $ENV_FILE"
