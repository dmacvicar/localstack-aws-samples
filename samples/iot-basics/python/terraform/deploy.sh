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
THING_NAME=$(terraform output -raw thing_name)
THING_ARN=$(terraform output -raw thing_arn)
POLICY_NAME=$(terraform output -raw policy_name)
POLICY_ARN=$(terraform output -raw policy_arn)
RULE_NAME=$(terraform output -raw rule_name)
IOT_ENDPOINT=""

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
