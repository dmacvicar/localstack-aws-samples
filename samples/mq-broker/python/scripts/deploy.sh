#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BROKER_NAME="mq-broker-$(date +%s)"
USERNAME="admin"
PASSWORD="Admin123456!"

echo "Creating MQ broker: $BROKER_NAME"
BROKER_ID=$(awslocal mq create-broker \
    --broker-name "$BROKER_NAME" \
    --deployment-mode SINGLE_INSTANCE \
    --engine-type ACTIVEMQ \
    --engine-version '5.18' \
    --host-instance-type 'mq.m5.large' \
    --auto-minor-version-upgrade \
    --publicly-accessible \
    --users "{\"ConsoleAccess\": true, \"Groups\": [\"admin\"], \"Password\": \"$PASSWORD\", \"Username\": \"$USERNAME\"}" \
    | jq -r '.BrokerId')

echo "Created MQ broker with ID: $BROKER_ID"

# Wait for broker to be ready
echo "Waiting for broker to start..."
sleep 2

# Get broker details
BROKER_INFO=$(awslocal mq describe-broker --broker-id "$BROKER_ID")
BROKER_ARN=$(echo "$BROKER_INFO" | jq -r '.BrokerArn')
CONSOLE_URL=$(echo "$BROKER_INFO" | jq -r '.BrokerInstances[0].ConsoleURL')
BROKER_STATE=$(echo "$BROKER_INFO" | jq -r '.BrokerState')

# Extract host and port from console URL
# URL format: http://localhost:4510 or similar
BROKER_HOST=$(echo "$CONSOLE_URL" | sed 's|http://||' | cut -d':' -f1)
BROKER_PORT=$(echo "$CONSOLE_URL" | sed 's|http://||' | cut -d':' -f2)

# Save configuration for tests
cat > "$SCRIPT_DIR/.env" << EOF
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
echo "Broker State: $BROKER_STATE"
echo "Console URL: $CONSOLE_URL"
