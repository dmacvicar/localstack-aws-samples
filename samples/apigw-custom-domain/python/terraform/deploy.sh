#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Deploying API Gateway Custom Domain Sample via Terraform"

cd "$SCRIPT_DIR"

# Determine Terraform CLI to use
if command -v tflocal &> /dev/null; then
    TF="tflocal"
else
    echo "Warning: tflocal not found, using terraform with manual endpoint config"
    TF="terraform"
fi

# Initialize Terraform
echo "Step 1: Initializing Terraform..."
$TF init -input=false

# Apply configuration
echo "Step 2: Applying Terraform configuration..."
$TF apply -auto-approve -input=false

# Extract outputs
echo "Step 3: Extracting outputs..."
FUNCTION_NAME=$($TF output -raw function_name)
API_ID=$($TF output -raw api_id)
API_ENDPOINT=$($TF output -raw api_endpoint)
DOMAIN_NAME=$($TF output -raw domain_name)
CERT_ARN=$($TF output -raw cert_arn)
HOSTED_ZONE_ID=$($TF output -raw hosted_zone_id)

# Save config for test script (shared with scripts/)
cat > "$SCRIPT_DIR/../scripts/.env" << EOF
FUNCTION_NAME=$FUNCTION_NAME
API_ID=$API_ID
API_ENDPOINT=$API_ENDPOINT
DOMAIN_NAME=$DOMAIN_NAME
CERT_ARN=$CERT_ARN
HOSTED_ZONE_ID=$HOSTED_ZONE_ID
REGION=us-east-1
EOF

echo ""
echo "Deployment complete!"
echo "  Function Name: $FUNCTION_NAME"
echo "  API ID: $API_ID"
echo "  API Endpoint: $API_ENDPOINT"
echo "  Domain: $DOMAIN_NAME"
echo ""
echo "Run tests with: ../scripts/test.sh"
