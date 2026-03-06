#!/bin/bash
set -euo pipefail

# Neptune Graph Database teardown script
# Cleans up all Neptune resources

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment if exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

CLUSTER_ID="${CLUSTER_ID:-neptune-test-cluster}"
AWS_REGION="${AWS_DEFAULT_REGION:-us-east-1}"

echo "Tearing down Neptune cluster: $CLUSTER_ID"

# Delete the Neptune cluster
awslocal neptune delete-db-cluster \
    --db-cluster-identifier "$CLUSTER_ID" \
    --skip-final-snapshot \
    --region "$AWS_REGION" 2>/dev/null || echo "Cluster may not exist"

echo "Neptune cluster deleted"

# Clean up .env file
rm -f "$SCRIPT_DIR/.env"

echo "Teardown complete"
