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
FUNCTION_NAME=$(terraform output -raw function_name)
FUNCTION_ARN=$(terraform output -raw function_arn)
ROLE_NAME=$(terraform output -raw role_name)
ROLE_ARN=$(terraform output -raw role_arn)

# Save configuration for tests
cat > "$SAMPLE_DIR/scripts/.env" << EOF
FUNCTION_NAME=$FUNCTION_NAME
FUNCTION_ARN=$FUNCTION_ARN
ROLE_NAME=$ROLE_NAME
ROLE_ARN=$ROLE_ARN
EOF

echo ""
echo "Deployment complete!"
echo "Function: $FUNCTION_NAME"
echo "X-Ray Tracing: Active"
