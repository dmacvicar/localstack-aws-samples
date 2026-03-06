#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"

STACK_NAME="mq-broker"
BROKER_SUFFIX=$(date +%s)

echo "Creating CloudFormation stack: $STACK_NAME"
awslocal cloudformation create-stack \
    --stack-name "$STACK_NAME" \
    --template-body "file://$SCRIPT_DIR/template.yml" \
    --parameters "ParameterKey=BrokerSuffix,ParameterValue=$BROKER_SUFFIX"

echo "Waiting for stack creation..."
awslocal cloudformation wait stack-create-complete --stack-name "$STACK_NAME"

# Get outputs
BROKER_ID=$(awslocal cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[?OutputKey==`BrokerId`].OutputValue' --output text)
BROKER_NAME=$(awslocal cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[?OutputKey==`BrokerName`].OutputValue' --output text)
BROKER_ARN=$(awslocal cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[?OutputKey==`BrokerArn`].OutputValue' --output text)
USERNAME=$(awslocal cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[?OutputKey==`Username`].OutputValue' --output text)
PASSWORD=$(awslocal cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[?OutputKey==`Password`].OutputValue' --output text)

# Get console URL from broker
BROKER_INFO=$(awslocal mq describe-broker --broker-id "$BROKER_ID")
CONSOLE_URL=$(echo "$BROKER_INFO" | jq -r '.BrokerInstances[0].ConsoleURL // ""')

# Extract host and port
if [ -n "$CONSOLE_URL" ]; then
    BROKER_HOST=$(echo "$CONSOLE_URL" | sed 's|http://||' | cut -d':' -f1)
    BROKER_PORT=$(echo "$CONSOLE_URL" | sed 's|http://||' | cut -d':' -f2)
else
    BROKER_HOST=""
    BROKER_PORT=""
fi

# Save configuration for tests
cat > "$SAMPLE_DIR/scripts/.env" << EOF
STACK_NAME=$STACK_NAME
BROKER_ID=$BROKER_ID
BROKER_NAME=$BROKER_NAME
BROKER_ARN=$BROKER_ARN
CONSOLE_URL=$CONSOLE_URL
BROKER_HOST=$BROKER_HOST
BROKER_PORT=$BROKER_PORT
USERNAME=$USERNAME
PASSWORD=$PASSWORD
EOF

echo ""
echo "Deployment complete!"
echo "Broker ID: $BROKER_ID"
echo "Broker Name: $BROKER_NAME"
echo "Console URL: $CONSOLE_URL"
