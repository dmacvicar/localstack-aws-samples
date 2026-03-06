#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"

cd "$SCRIPT_DIR"

echo "Installing CDK dependencies..."
pip install -q -r requirements.txt

echo "Bootstrapping CDK (if needed)..."
cdklocal bootstrap --quiet 2>/dev/null || true

echo "Deploying CDK stack..."
cdklocal deploy --require-approval never --outputs-file outputs.json

# Extract outputs
BROKER_ID=$(jq -r '.MQBrokerStack.BrokerId' outputs.json)
BROKER_NAME=$(jq -r '.MQBrokerStack.BrokerName' outputs.json)
BROKER_ARN=$(jq -r '.MQBrokerStack.BrokerArn' outputs.json)
USERNAME=$(jq -r '.MQBrokerStack.Username' outputs.json)
PASSWORD=$(jq -r '.MQBrokerStack.Password' outputs.json)

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
