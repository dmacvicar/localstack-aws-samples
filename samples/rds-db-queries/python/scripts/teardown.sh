#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LOCALSTACK_ENDPOINT="${LOCALSTACK_ENDPOINT:-http://localhost.localstack.cloud:4566}"

if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"

    echo "Deleting RDS instance ${DB_INSTANCE_ID}..."
    awslocal rds delete-db-instance \
        --db-instance-identifier "$DB_INSTANCE_ID" \
        --skip-final-snapshot \
        --endpoint-url "$LOCALSTACK_ENDPOINT" 2>/dev/null || true

    rm -f "$SCRIPT_DIR/.env"
fi

echo "Teardown complete"
