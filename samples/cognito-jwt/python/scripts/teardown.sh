#!/bin/bash
set -euo pipefail

# Cognito JWT teardown script
# Cleans up all Cognito resources

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment if exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

POOL_ID="${POOL_ID:-}"
CLIENT_ID="${CLIENT_ID:-}"
ADMIN_USER="${ADMIN_USER:-admin_user}"

echo "Tearing down Cognito resources..."

if [ -n "$POOL_ID" ]; then
    # Delete users from pool
    echo "Deleting users from pool..."
    for username in $(awslocal cognito-idp list-users --user-pool-id "$POOL_ID" 2>/dev/null | jq -r '.Users[].Username' 2>/dev/null || true); do
        echo "  Deleting user: $username"
        awslocal cognito-idp admin-delete-user \
            --user-pool-id "$POOL_ID" \
            --username "$username" 2>/dev/null || true
    done

    # Delete clients from pool
    if [ -n "$CLIENT_ID" ]; then
        echo "Deleting client: $CLIENT_ID"
        awslocal cognito-idp delete-user-pool-client \
            --user-pool-id "$POOL_ID" \
            --client-id "$CLIENT_ID" 2>/dev/null || true
    fi

    # Delete user pool
    echo "Deleting User Pool: $POOL_ID"
    awslocal cognito-idp delete-user-pool \
        --user-pool-id "$POOL_ID" 2>/dev/null || true
fi

# Clean up .env file
rm -f "$SCRIPT_DIR/.env"

echo "Teardown complete"
