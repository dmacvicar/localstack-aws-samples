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
THING_NAME=$(jq -r '.IoTBasicsStack.ThingName' outputs.json)
THING_ARN=$(jq -r '.IoTBasicsStack.ThingArn' outputs.json)
POLICY_NAME=$(jq -r '.IoTBasicsStack.PolicyName' outputs.json)
POLICY_ARN=$(jq -r '.IoTBasicsStack.PolicyArn' outputs.json)
RULE_NAME=$(jq -r '.IoTBasicsStack.RuleName' outputs.json)

# Get IoT endpoint (may fail if MQTT broker not available)
IOT_ENDPOINT=$(awslocal iot describe-endpoint --query 'endpointAddress' --output text 2>/dev/null || echo "")

# Save configuration for tests
cat > "$SAMPLE_DIR/scripts/.env" << EOF
THING_NAME=$THING_NAME
THING_ARN=$THING_ARN
POLICY_NAME=$POLICY_NAME
POLICY_ARN=$POLICY_ARN
RULE_NAME=$RULE_NAME
IOT_ENDPOINT=$IOT_ENDPOINT
EOF

echo ""
echo "Deployment complete!"
echo "Thing: $THING_NAME"
echo "Policy: $POLICY_NAME"
echo "Rule: $RULE_NAME"
