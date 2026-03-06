#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$SAMPLE_DIR/scripts/.env"

echo "Tearing down Lambda Event Filtering sample with Terraform..."

cd "$SCRIPT_DIR"

# Destroy Terraform resources
terraform destroy -auto-approve

# Clean up
rm -f "$ENV_FILE"
rm -f terraform.tfstate terraform.tfstate.backup
rm -f handler.zip
rm -rf .terraform .terraform.lock.hcl

echo "Teardown complete!"
