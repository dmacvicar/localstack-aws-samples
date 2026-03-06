#!/bin/bash
set -euo pipefail

# Chalice REST API deployment script
# Deploys the Chalice app to LocalStack using chalice-local

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"

echo "Deploying Chalice REST API..."

# Check if chalice-local is available
if ! command -v chalice-local &> /dev/null; then
    echo ""
    echo "WARNING: chalice-local is not installed."
    echo "Install with: pip install chalice-local chalice"
    echo ""
    CHALICE_AVAILABLE="false"

    cat > "$SCRIPT_DIR/.env" << EOF
CHALICE_AVAILABLE=false
API_URL=
EOF
    echo "Environment written to $SCRIPT_DIR/.env"
    exit 0
fi

CHALICE_AVAILABLE="true"

# Change to sample directory for chalice deployment
cd "$SAMPLE_DIR"

# Deploy using chalice-local
echo "Running chalice-local deploy..."
DEPLOY_OUTPUT=$(chalice-local deploy 2>&1) || {
    echo "Deployment failed: $DEPLOY_OUTPUT"
    cat > "$SCRIPT_DIR/.env" << EOF
CHALICE_AVAILABLE=true
DEPLOY_SUCCESS=false
API_URL=
EOF
    exit 1
}

echo "$DEPLOY_OUTPUT"

# Extract API URL from output
# chalice-local outputs: Rest API URL: https://xxx.execute-api...
API_URL=$(echo "$DEPLOY_OUTPUT" | grep -oP 'Rest API URL: \K.*' || echo "")

if [ -z "$API_URL" ]; then
    # Try alternate format
    API_URL=$(echo "$DEPLOY_OUTPUT" | grep -oP 'https?://[^ ]+' | head -1 || echo "")
fi

echo ""
echo "Chalice REST API deployed successfully!"
echo "  API URL: $API_URL"

# Write environment variables
cat > "$SCRIPT_DIR/.env" << EOF
CHALICE_AVAILABLE=true
DEPLOY_SUCCESS=true
API_URL=$API_URL
EOF

echo ""
echo "Environment written to $SCRIPT_DIR/.env"
