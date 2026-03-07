#!/bin/bash
set -euo pipefail

# Chalice REST API Terraform deployment script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$SAMPLE_DIR/scripts/.env"

echo "Deploying Chalice REST API with Terraform..."

cd "$SCRIPT_DIR"

# Initialize Terraform
tflocal init -input=false

# Apply configuration
tflocal apply -auto-approve

# Extract outputs
API_ID=$(tflocal output -raw api_id)
API_URL=$(tflocal output -raw api_url)
FUNCTION_NAME=$(tflocal output -raw function_name)

echo ""
echo "Chalice REST API deployed successfully!"
echo "  API ID: $API_ID"
echo "  API URL: $API_URL"
echo "  Function: $FUNCTION_NAME"

# Write environment variables
mkdir -p "$(dirname "$ENV_FILE")"
cat > "$ENV_FILE" << EOF
CHALICE_AVAILABLE=true
DEPLOY_SUCCESS=true
API_URL=$API_URL
API_ID=$API_ID
FUNCTION_NAME=$FUNCTION_NAME
EOF

echo ""
echo "Environment written to $ENV_FILE"
