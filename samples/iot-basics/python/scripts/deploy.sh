#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SUFFIX=$(date +%s)
THING_NAME="iot-thing-$SUFFIX"
POLICY_NAME="iot-policy-$SUFFIX"

echo "Creating IoT Thing: $THING_NAME"
THING_RESULT=$(awslocal iot create-thing --thing-name "$THING_NAME" \
    --attribute-payload '{"attributes": {"env": "test", "version": "1.0"}}')
THING_ARN=$(echo "$THING_RESULT" | jq -r '.thingArn')

echo "Creating IoT Policy: $POLICY_NAME"
POLICY_DOC='{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": ["iot:Connect", "iot:Publish", "iot:Subscribe", "iot:Receive"],
            "Resource": "*"
        }
    ]
}'
POLICY_RESULT=$(awslocal iot create-policy \
    --policy-name "$POLICY_NAME" \
    --policy-document "$POLICY_DOC")
POLICY_ARN=$(echo "$POLICY_RESULT" | jq -r '.policyArn')

echo "Creating IoT Topic Rule..."
RULE_NAME="rule_$SUFFIX"
awslocal iot create-topic-rule \
    --rule-name "$RULE_NAME" \
    --topic-rule-payload '{
        "sql": "SELECT * FROM '\''iot/sensor/+'\''"  ,
        "ruleDisabled": false,
        "actions": []
    }'

echo "Getting IoT endpoint..."
IOT_ENDPOINT=$(awslocal iot describe-endpoint --query 'endpointAddress' --output text 2>/dev/null || echo "")

# Save configuration for tests
cat > "$SCRIPT_DIR/.env" << EOF
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
echo "IoT Endpoint: $IOT_ENDPOINT"
