#!/bin/bash
set -euo pipefail

# Chalice REST API teardown script
# Removes the Chalice app from LocalStack

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"

echo "Tearing down Chalice REST API..."

# Check if chalice-local is available
if command -v chalice-local &> /dev/null; then
    cd "$SAMPLE_DIR"
    chalice-local delete 2>/dev/null || true
    echo "Chalice app deleted"
fi

# Clean up .chalice deployed directory
rm -rf "$SAMPLE_DIR/.chalice/deployed"

# Clean up .env file
rm -f "$SCRIPT_DIR/.env"

echo "Teardown complete"
