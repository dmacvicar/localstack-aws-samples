#!/bin/bash
set -euo pipefail

# CloudWatch Metrics deployment script
# Creates Lambda, SNS topic, and CloudWatch alarm

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration
FUNCTION_NAME="${FUNCTION_NAME:-cw-failing-lambda}"
TOPIC_NAME="${TOPIC_NAME:-cw-alarm-topic}"
ALARM_NAME="${ALARM_NAME:-cw-lambda-alarm}"
TEST_EMAIL="${TEST_EMAIL:-test@example.com}"
AWS_REGION="${AWS_DEFAULT_REGION:-us-east-1}"

echo "Setting up CloudWatch metrics resources..."

# Clean up any existing resources
awslocal lambda delete-function --function-name "$FUNCTION_NAME" 2>/dev/null || true
awslocal cloudwatch delete-alarms --alarm-names "$ALARM_NAME" 2>/dev/null || true

# Create the Lambda deployment package
echo "Creating Lambda function: $FUNCTION_NAME"
cd "$SAMPLE_DIR"
zip -j /tmp/handler.zip handler.py >/dev/null

# Create Lambda function
awslocal lambda create-function \
    --function-name "$FUNCTION_NAME" \
    --runtime python3.11 \
    --handler handler.lambda_handler \
    --zip-file fileb:///tmp/handler.zip \
    --role arn:aws:iam::000000000000:role/lambda-role \
    --timeout 30 \
    --output json >/dev/null

# Wait for Lambda to be active
echo "Waiting for Lambda to be active..."
for i in {1..30}; do
    STATE=$(awslocal lambda get-function --function-name "$FUNCTION_NAME" \
        --query 'Configuration.State' --output text 2>/dev/null || echo "Pending")
    if [ "$STATE" = "Active" ]; then
        echo "Lambda is active"
        break
    fi
    sleep 1
done

# Get Lambda ARN
LAMBDA_ARN=$(awslocal lambda get-function --function-name "$FUNCTION_NAME" \
    --query 'Configuration.FunctionArn' --output text)

# Create SNS topic for alarm notifications
echo "Creating SNS topic: $TOPIC_NAME"
TOPIC_ARN=$(awslocal sns create-topic --name "$TOPIC_NAME" --query 'TopicArn' --output text)

# Subscribe email to topic (requires SMTP for actual delivery)
echo "Subscribing email to topic..."
SUBSCRIPTION_ARN=$(awslocal sns subscribe \
    --topic-arn "$TOPIC_ARN" \
    --protocol email \
    --notification-endpoint "$TEST_EMAIL" \
    --query 'SubscriptionArn' --output text 2>/dev/null || echo "pending")

# Create CloudWatch alarm on Lambda errors
echo "Creating CloudWatch alarm: $ALARM_NAME"
awslocal cloudwatch put-metric-alarm \
    --alarm-name "$ALARM_NAME" \
    --metric-name Errors \
    --namespace AWS/Lambda \
    --dimensions "Name=FunctionName,Value=$FUNCTION_NAME" \
    --threshold 1 \
    --comparison-operator GreaterThanOrEqualToThreshold \
    --evaluation-periods 1 \
    --period 60 \
    --statistic Sum \
    --treat-missing-data notBreaching \
    --alarm-actions "$TOPIC_ARN"

# Get alarm state
ALARM_STATE=$(awslocal cloudwatch describe-alarms \
    --alarm-names "$ALARM_NAME" \
    --query 'MetricAlarms[0].StateValue' --output text)

echo ""
echo "CloudWatch resources created successfully!"
echo "  Lambda: $FUNCTION_NAME"
echo "  Lambda ARN: $LAMBDA_ARN"
echo "  SNS Topic: $TOPIC_ARN"
echo "  Alarm: $ALARM_NAME"
echo "  Alarm State: $ALARM_STATE"

# Check SMTP configuration
SMTP_CONFIGURED="false"
if [ -n "${SMTP_HOST:-}" ]; then
    SMTP_CONFIGURED="true"
    echo "  SMTP: Configured ($SMTP_HOST)"
else
    echo "  SMTP: Not configured (email notifications will not be delivered)"
fi

# Write environment variables
cat > "$SCRIPT_DIR/.env" << EOF
FUNCTION_NAME=$FUNCTION_NAME
LAMBDA_ARN=$LAMBDA_ARN
TOPIC_NAME=$TOPIC_NAME
TOPIC_ARN=$TOPIC_ARN
ALARM_NAME=$ALARM_NAME
ALARM_STATE=$ALARM_STATE
TEST_EMAIL=$TEST_EMAIL
SMTP_CONFIGURED=$SMTP_CONFIGURED
EOF

echo ""
echo "Environment written to $SCRIPT_DIR/.env"
