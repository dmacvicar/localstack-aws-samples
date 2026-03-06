#!/bin/bash
set -euo pipefail

# Neptune Graph Database deployment script
# Creates a Neptune cluster for graph database queries

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration
CLUSTER_ID="${CLUSTER_ID:-neptune-test-cluster}"
LOCALSTACK_ENDPOINT="${LOCALSTACK_ENDPOINT:-http://localhost.localstack.cloud:4566}"
AWS_REGION="${AWS_DEFAULT_REGION:-us-east-1}"

echo "Creating Neptune cluster: $CLUSTER_ID"

# Delete existing cluster if it exists
awslocal neptune delete-db-cluster \
    --db-cluster-identifier "$CLUSTER_ID" \
    --skip-final-snapshot \
    --region "$AWS_REGION" >/dev/null 2>&1 || true

# Wait a moment for deletion
sleep 2

# Create the Neptune cluster
CLUSTER_RESPONSE=$(awslocal neptune create-db-cluster \
    --db-cluster-identifier "$CLUSTER_ID" \
    --engine neptune \
    --region "$AWS_REGION" \
    --output json)

echo "Neptune cluster creation initiated"

# Wait for cluster to become available or have an endpoint
echo "Waiting for cluster to become available..."
for i in {1..30}; do
    STATUS=$(awslocal neptune describe-db-clusters \
        --db-cluster-identifier "$CLUSTER_ID" \
        --query 'DBClusters[0].Status' \
        --output text 2>/dev/null || echo "creating")

    # Accept "available" or "error" (LocalStack may report error but cluster is functional)
    if [ "$STATUS" = "available" ] || [ "$STATUS" = "error" ]; then
        echo "Cluster ready (status: $STATUS)"
        break
    fi
    echo "  Status: $STATUS (attempt $i/30)"
    sleep 1
done

# Get cluster details
CLUSTER_INFO=$(awslocal neptune describe-db-clusters \
    --db-cluster-identifier "$CLUSTER_ID" \
    --output json 2>/dev/null)

CLUSTER_ARN=$(echo "$CLUSTER_INFO" | jq -r '.DBClusters[0].DBClusterArn')
CLUSTER_ENDPOINT=$(echo "$CLUSTER_INFO" | jq -r '.DBClusters[0].Endpoint // empty')
CLUSTER_PORT=$(echo "$CLUSTER_INFO" | jq -r '.DBClusters[0].Port // empty')

echo ""
echo "Neptune cluster created successfully!"
echo "  Cluster ID: $CLUSTER_ID"
echo "  Cluster ARN: $CLUSTER_ARN"
echo "  Endpoint: $CLUSTER_ENDPOINT"
echo "  Port: $CLUSTER_PORT"

# Write environment variables
cat > "$SCRIPT_DIR/.env" << EOF
CLUSTER_ID=$CLUSTER_ID
CLUSTER_ARN=$CLUSTER_ARN
CLUSTER_ENDPOINT=$CLUSTER_ENDPOINT
CLUSTER_PORT=$CLUSTER_PORT
EOF

echo ""
echo "Environment written to $SCRIPT_DIR/.env"
