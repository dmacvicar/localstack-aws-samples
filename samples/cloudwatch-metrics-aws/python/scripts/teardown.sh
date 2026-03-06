#!/bin/bash
set -euo pipefail

# CloudWatch Metrics teardown script
# Cleans up all CloudWatch, SNS, and Lambda resources

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment if exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

FUNCTION_NAME="${FUNCTION_NAME:-cw-failing-lambda}"
TOPIC_NAME="${TOPIC_NAME:-cw-alarm-topic}"
ALARM_NAME="${ALARM_NAME:-cw-lambda-alarm}"
TOPIC_ARN="${TOPIC_ARN:-}"

echo "Tearing down CloudWatch metrics resources..."

# Delete CloudWatch alarm
echo "Deleting alarm: $ALARM_NAME"
awslocal cloudwatch delete-alarms --alarm-names "$ALARM_NAME" 2>/dev/null || true

# Delete SNS subscriptions and topic
if [ -n "$TOPIC_ARN" ]; then
    echo "Deleting SNS topic subscriptions..."
    for sub_arn in $(awslocal sns list-subscriptions-by-topic --topic-arn "$TOPIC_ARN" 2>/dev/null | jq -r '.Subscriptions[].SubscriptionArn' 2>/dev/null || true); do
        if [ "$sub_arn" != "PendingConfirmation" ]; then
            awslocal sns unsubscribe --subscription-arn "$sub_arn" 2>/dev/null || true
        fi
    done

    echo "Deleting SNS topic: $TOPIC_NAME"
    awslocal sns delete-topic --topic-arn "$TOPIC_ARN" 2>/dev/null || true
fi

# Delete Lambda function
echo "Deleting Lambda: $FUNCTION_NAME"
awslocal lambda delete-function --function-name "$FUNCTION_NAME" 2>/dev/null || true

# Clean up temp files
rm -f /tmp/handler.zip

# Clean up .env file
rm -f "$SCRIPT_DIR/.env"

echo "Teardown complete"
