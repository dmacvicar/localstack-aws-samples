#!/bin/bash
set -euo pipefail

# Chalice REST API Terraform teardown script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$SAMPLE_DIR/scripts/.env"

echo "Tearing down Chalice REST API Terraform resources..."

cd "$SCRIPT_DIR"

# Destroy resources
tflocal destroy -auto-approve 2>/dev/null || true

# Clean up
rm -f "$ENV_FILE"
rm -rf .terraform
rm -f .terraform.lock.hcl
rm -f terraform.tfstate*
rm -f lambda.zip

echo "Teardown complete"
