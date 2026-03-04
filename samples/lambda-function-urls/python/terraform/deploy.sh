#!/bin/bash
set -euo pipefail

# =============================================================================
# Lambda Function URLs - Terraform Deployment
#
# Uses tflocal (terraform-local) to deploy to LocalStack
# Install: pip install terraform-local
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Deploying Lambda Function URL Sample via Terraform"

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
FUNCTION_URL=$($TF output -raw function_url)
LAMBDA_ARN=$($TF output -raw function_arn)

# Save config for test script (shared with scripts/)
cat > "$SCRIPT_DIR/../scripts/.env" << EOF
FUNCTION_NAME=$FUNCTION_NAME
FUNCTION_URL=$FUNCTION_URL
LAMBDA_ARN=$LAMBDA_ARN
REGION=us-east-1
EOF

echo ""
echo "Deployment complete!"
echo "  Function Name: $FUNCTION_NAME"
echo "  Function URL: $FUNCTION_URL"
echo ""
echo "Run tests with: ../scripts/test.sh"
