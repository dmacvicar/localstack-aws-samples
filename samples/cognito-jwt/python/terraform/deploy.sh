#!/bin/bash
set -euo pipefail

# Cognito JWT Terraform deployment script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$SAMPLE_DIR/scripts/.env"

# Configuration
ADMIN_USER="${ADMIN_USER:-admin_user}"
TEST_PASSWORD="${TEST_PASSWORD:-TestPassword123!}"

echo "Deploying Cognito JWT with Terraform..."

cd "$SCRIPT_DIR"

# Initialize Terraform
tflocal init -input=false

# Apply configuration
tflocal apply -auto-approve -input=false

# Extract outputs
POOL_NAME=$(tflocal output -raw pool_name)
POOL_ID=$(tflocal output -raw pool_id)
POOL_ARN=$(tflocal output -raw pool_arn)
CLIENT_NAME=$(tflocal output -raw client_name)
CLIENT_ID=$(tflocal output -raw client_id)

# Create admin user (Terraform doesn't have a resource for Cognito users)
echo "Creating admin user: $ADMIN_USER"
awslocal cognito-idp admin-create-user \
    --user-pool-id "$POOL_ID" \
    --username "$ADMIN_USER" \
    --message-action SUPPRESS \
    --output json >/dev/null 2>&1 || true

# Set permanent password
echo "Setting user password..."
awslocal cognito-idp admin-set-user-password \
    --user-pool-id "$POOL_ID" \
    --username "$ADMIN_USER" \
    --password "$TEST_PASSWORD" \
    --permanent

# Test authentication
echo "Testing authentication..."
AUTH_RESPONSE=$(awslocal cognito-idp admin-initiate-auth \
    --user-pool-id "$POOL_ID" \
    --client-id "$CLIENT_ID" \
    --auth-flow ADMIN_USER_PASSWORD_AUTH \
    --auth-parameters "USERNAME=$ADMIN_USER,PASSWORD=$TEST_PASSWORD" \
    --output json 2>/dev/null || echo '{}')

ACCESS_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.AuthenticationResult.AccessToken // empty')
ID_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.AuthenticationResult.IdToken // empty')
REFRESH_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.AuthenticationResult.RefreshToken // empty')

if [ -n "$ACCESS_TOKEN" ]; then
    echo "Authentication successful!"
else
    echo "Authentication test skipped or failed"
fi

# Check SMTP configuration
SMTP_CONFIGURED="false"
if [ -n "${SMTP_HOST:-}" ]; then
    SMTP_CONFIGURED="true"
fi

echo ""
echo "Cognito resources created successfully!"
echo "  Pool ID: $POOL_ID"
echo "  Client ID: $CLIENT_ID"
echo "  Admin User: $ADMIN_USER"

# Write environment variables
mkdir -p "$(dirname "$ENV_FILE")"
cat > "$ENV_FILE" << EOF
POOL_NAME=$POOL_NAME
POOL_ID=$POOL_ID
POOL_ARN=$POOL_ARN
CLIENT_NAME=$CLIENT_NAME
CLIENT_ID=$CLIENT_ID
ADMIN_USER=$ADMIN_USER
TEST_PASSWORD=$TEST_PASSWORD
ACCESS_TOKEN=$ACCESS_TOKEN
ID_TOKEN=$ID_TOKEN
REFRESH_TOKEN=$REFRESH_TOKEN
SMTP_CONFIGURED=$SMTP_CONFIGURED
EOF

echo ""
echo "Environment written to $ENV_FILE"
