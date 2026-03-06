#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"

cd "$SCRIPT_DIR"

SUFFIX="${SUFFIX:-$(date +%s)}"
export TF_VAR_suffix="$SUFFIX"

echo "Initializing Terraform..."
terraform init -input=false

echo "Applying Terraform configuration..."
terraform apply -auto-approve -input=false

# Extract outputs
FUNCTION_NAME=$(terraform output -raw function_name)
FUNCTION_URL=$(terraform output -raw function_url)
ROLE_NAME=$(terraform output -raw role_name)

# Save configuration for tests
cat > "$SAMPLE_DIR/scripts/.env" << EOF
FUNCTION_NAME=$FUNCTION_NAME
FUNCTION_URL=$FUNCTION_URL
ROLE_NAME=$ROLE_NAME
EOF

echo ""
echo "Deployment complete!"
echo "Function Name: $FUNCTION_NAME"
echo "Function URL: $FUNCTION_URL"
