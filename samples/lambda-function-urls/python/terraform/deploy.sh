#!/bin/bash
set -euo pipefail

# =============================================================================
# Lambda Function URLs - Terraform Deployment
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Deploying Lambda Function URL Sample via Terraform"

cd "$SCRIPT_DIR"

# Initialize Terraform
echo "Step 1: Initializing Terraform..."
terraform init -input=false

# Apply configuration
echo "Step 2: Applying Terraform configuration..."
terraform apply -auto-approve -input=false

# Extract outputs
echo "Step 3: Extracting outputs..."
FUNCTION_NAME=$(terraform output -raw function_name)
FUNCTION_URL=$(terraform output -raw function_url)
LAMBDA_ARN=$(terraform output -raw function_arn)

# Save config for test script
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
