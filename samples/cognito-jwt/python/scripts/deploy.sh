#!/bin/bash
set -euo pipefail

# Cognito JWT deployment script
# Creates Cognito User Pool, Client, and test users

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration
POOL_NAME="${POOL_NAME:-test-user-pool}"
CLIENT_NAME="${CLIENT_NAME:-test-client}"
ADMIN_USER="${ADMIN_USER:-admin_user}"
TEST_PASSWORD="${TEST_PASSWORD:-TestPassword123!}"
AWS_REGION="${AWS_DEFAULT_REGION:-us-east-1}"

echo "Setting up Cognito resources..."

# Create User Pool
echo "Creating User Pool: $POOL_NAME"
POOL_RESPONSE=$(awslocal cognito-idp create-user-pool \
    --pool-name "$POOL_NAME" \
    --policies '{"PasswordPolicy":{"MinimumLength":8,"RequireUppercase":true,"RequireLowercase":true,"RequireNumbers":true,"RequireSymbols":false}}' \
    --auto-verified-attributes email \
    --output json)

POOL_ID=$(echo "$POOL_RESPONSE" | jq -r '.UserPool.Id')
POOL_ARN=$(echo "$POOL_RESPONSE" | jq -r '.UserPool.Arn')
echo "Created User Pool: $POOL_ID"

# Create User Pool Client
echo "Creating User Pool Client: $CLIENT_NAME"
CLIENT_RESPONSE=$(awslocal cognito-idp create-user-pool-client \
    --user-pool-id "$POOL_ID" \
    --client-name "$CLIENT_NAME" \
    --explicit-auth-flows ADMIN_NO_SRP_AUTH ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
    --output json)

CLIENT_ID=$(echo "$CLIENT_RESPONSE" | jq -r '.UserPoolClient.ClientId')
echo "Created Client: $CLIENT_ID"

# Create admin user (using admin workflow - no email verification needed)
echo "Creating admin user: $ADMIN_USER"
awslocal cognito-idp admin-create-user \
    --user-pool-id "$POOL_ID" \
    --username "$ADMIN_USER" \
    --message-action SUPPRESS \
    --output json >/dev/null

# Set permanent password (bypasses email verification)
echo "Setting user password..."
awslocal cognito-idp admin-set-user-password \
    --user-pool-id "$POOL_ID" \
    --username "$ADMIN_USER" \
    --password "$TEST_PASSWORD" \
    --permanent

# Verify user can authenticate
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
    echo "SMTP: Configured ($SMTP_HOST)"
else
    echo "SMTP: Not configured (email verification flows will not work)"
fi

echo ""
echo "Cognito resources created successfully!"
echo "  Pool ID: $POOL_ID"
echo "  Client ID: $CLIENT_ID"
echo "  Admin User: $ADMIN_USER"

# Write environment variables
cat > "$SCRIPT_DIR/.env" << EOF
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
echo "Environment written to $SCRIPT_DIR/.env"
