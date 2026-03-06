#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"

cd "$SCRIPT_DIR"

if [ -f "terraform.tfstate" ]; then
    echo "Destroying Terraform resources..."
    terraform destroy -auto-approve -input=false 2>/dev/null || true
fi

rm -f "$SAMPLE_DIR/scripts/.env"
rm -rf .terraform .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup function.zip
echo "Teardown complete"
