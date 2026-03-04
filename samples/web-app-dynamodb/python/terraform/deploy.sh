#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Deploying Web App DynamoDB via Terraform"

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
FUNCTION_NAME=$($TF output -raw function_name)
FUNCTION_URL=$($TF output -raw function_url)
TABLE_NAME=$($TF output -raw table_name)

cat > "$SCRIPT_DIR/../scripts/.env" << EOF
FUNCTION_NAME=$FUNCTION_NAME
FUNCTION_URL=$FUNCTION_URL
TABLE_NAME=$TABLE_NAME
REGION=us-east-1
EOF

echo ""
echo "Deployment complete!"
echo "  Function: $FUNCTION_NAME"
echo "  Table: $TABLE_NAME"
echo "  URL: $FUNCTION_URL"
