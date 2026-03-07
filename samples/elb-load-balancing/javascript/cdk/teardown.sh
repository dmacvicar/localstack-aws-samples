#!/bin/bash
set -euo pipefail

# ELB Load Balancing CDK teardown script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$SAMPLE_DIR/scripts/.env"
STACK_NAME="ElbLoadBalancingStack"

echo "Tearing down ELB load balancing CDK resources..."

cd "$SCRIPT_DIR"

# Destroy stack
cdklocal destroy "$STACK_NAME" --force 2>/dev/null || true

# Clean up
rm -f "$ENV_FILE"
rm -f outputs.json
rm -rf cdk.out

echo "Teardown complete"
