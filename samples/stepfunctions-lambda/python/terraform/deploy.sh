#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Deploying Step Functions Lambda via Terraform"

cd "$SCRIPT_DIR"

if command -v tflocal &> /dev/null; then
    TF="tflocal"
else
    TF="terraform"
fi

echo "Step 1: Initializing Terraform..."
$TF init -input=false

echo "Step 2: Applying Terraform configuration..."
$TF apply -auto-approve -input=false

echo "Step 3: Extracting outputs..."
ADAM_FUNCTION=$($TF output -raw adam_function)
ADAM_ARN=$($TF output -raw adam_arn)
COLE_FUNCTION=$($TF output -raw cole_function)
COLE_ARN=$($TF output -raw cole_arn)
COMBINE_FUNCTION=$($TF output -raw combine_function)
COMBINE_ARN=$($TF output -raw combine_arn)
STATE_MACHINE_NAME=$($TF output -raw state_machine_name)
STATE_MACHINE_ARN=$($TF output -raw state_machine_arn)

cat > "$SCRIPT_DIR/../scripts/.env" << EOF
ADAM_FUNCTION=$ADAM_FUNCTION
ADAM_ARN=$ADAM_ARN
COLE_FUNCTION=$COLE_FUNCTION
COLE_ARN=$COLE_ARN
COMBINE_FUNCTION=$COMBINE_FUNCTION
COMBINE_ARN=$COMBINE_ARN
STATE_MACHINE_NAME=$STATE_MACHINE_NAME
STATE_MACHINE_ARN=$STATE_MACHINE_ARN
REGION=us-east-1
EOF

echo ""
echo "Deployment complete!"
echo "  State Machine: $STATE_MACHINE_NAME"
echo "  Adam Function: $ADAM_FUNCTION"
echo "  Cole Function: $COLE_FUNCTION"
echo "  Combine Function: $COMBINE_FUNCTION"
