#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"

cd "$SCRIPT_DIR"

echo "Initializing Terraform..."
terraform init -input=false

echo "Applying Terraform configuration..."
terraform apply -auto-approve -input=false

# Extract outputs
BROKER_ID=$(terraform output -raw broker_id)
BROKER_NAME=$(terraform output -raw broker_name)
BROKER_ARN=$(terraform output -raw broker_arn)
CONSOLE_URL=$(terraform output -raw console_url 2>/dev/null || echo "")
USERNAME=$(terraform output -raw username)
PASSWORD=$(terraform output -raw password)

# Extract host and port from console URL if available
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
