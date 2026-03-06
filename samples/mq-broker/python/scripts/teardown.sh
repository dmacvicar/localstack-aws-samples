#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
else
    echo "No .env file found. Nothing to tear down."
    exit 0
fi

if [ -n "${BROKER_ID:-}" ]; then
    echo "Deleting MQ broker: $BROKER_ID"
    awslocal mq delete-broker --broker-id "$BROKER_ID" || true
fi

# Clean up .env file
rm -f "$SCRIPT_DIR/.env"

echo "Teardown complete!"
