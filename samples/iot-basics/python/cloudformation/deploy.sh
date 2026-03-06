#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"

STACK_NAME="iot-basics"
SUFFIX=$(date +%s)

echo "Creating CloudFormation stack: $STACK_NAME"
awslocal cloudformation create-stack \
    --stack-name "$STACK_NAME" \
    --template-body "file://$SCRIPT_DIR/template.yml" \
    --parameters "ParameterKey=Suffix,ParameterValue=$SUFFIX"

echo "Waiting for stack creation..."
awslocal cloudformation wait stack-create-complete --stack-name "$STACK_NAME"

# Get outputs
THING_NAME=$(awslocal cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[?OutputKey==`ThingName`].OutputValue' --output text)
THING_ARN=$(awslocal cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[?OutputKey==`ThingArn`].OutputValue' --output text)
POLICY_NAME=$(awslocal cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[?OutputKey==`PolicyName`].OutputValue' --output text)
POLICY_ARN=$(awslocal cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[?OutputKey==`PolicyArn`].OutputValue' --output text)
RULE_NAME=$(awslocal cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[?OutputKey==`RuleName`].OutputValue' --output text)

# Get IoT endpoint (may fail if MQTT broker not available)
IOT_ENDPOINT=$(awslocal iot describe-endpoint --query 'endpointAddress' --output text 2>/dev/null || echo "")

# Save configuration for tests
cat > "$SAMPLE_DIR/scripts/.env" << EOF
STACK_NAME=$STACK_NAME
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
