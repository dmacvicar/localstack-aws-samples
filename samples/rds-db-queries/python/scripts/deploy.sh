#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SUFFIX="${SUFFIX:-$(date +%s)}"
DB_INSTANCE_ID="rds-db-${SUFFIX}"
DB_NAME="testdb"
DB_USER="testuser"
DB_PASSWORD="testpass123"

LOCALSTACK_ENDPOINT="${LOCALSTACK_ENDPOINT:-http://localhost.localstack.cloud:4566}"

echo "Creating RDS PostgreSQL instance..."
echo "Note: First run may take time to download PostgreSQL Docker image"
awslocal rds create-db-instance \
    --db-instance-identifier "$DB_INSTANCE_ID" \
    --db-instance-class db.t3.micro \
    --engine postgres \
    --master-username "$DB_USER" \
    --master-user-password "$DB_PASSWORD" \
    --db-name "$DB_NAME" \
    --endpoint-url "$LOCALSTACK_ENDPOINT" > /dev/null

echo "Waiting for RDS instance to be available (may take a few minutes on first run)..."
for i in {1..60}; do
    STATUS=$(awslocal rds describe-db-instances \
        --db-instance-identifier "$DB_INSTANCE_ID" \
        --query "DBInstances[0].DBInstanceStatus" \
        --output text \
        --endpoint-url "$LOCALSTACK_ENDPOINT" 2>/dev/null || echo "creating")
    if [ "$STATUS" = "available" ]; then
        echo "RDS instance is available"
        break
    fi
    echo "Status: $STATUS, waiting... ($i/60)"
    sleep 5
done

# Get the endpoint info
DB_PORT=$(awslocal rds describe-db-instances \
    --db-instance-identifier "$DB_INSTANCE_ID" \
    --query "DBInstances[0].Endpoint.Port" \
    --output text \
    --endpoint-url "$LOCALSTACK_ENDPOINT")

DB_HOST=$(awslocal rds describe-db-instances \
    --db-instance-identifier "$DB_INSTANCE_ID" \
    --query "DBInstances[0].Endpoint.Address" \
    --output text \
    --endpoint-url "$LOCALSTACK_ENDPOINT")

# Save configuration for tests
cat > "$SCRIPT_DIR/.env" << EOF
DB_INSTANCE_ID=$DB_INSTANCE_ID
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
EOF

echo ""
echo "Deployment complete!"
echo "DB Instance ID: $DB_INSTANCE_ID"
echo "DB Host: $DB_HOST"
echo "DB Port: $DB_PORT"
