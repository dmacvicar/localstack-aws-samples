#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
else
    echo "No .env file found. Nothing to tear down."
    exit 0
fi

echo "Cleaning up IoT resources..."

if [ -n "${RULE_NAME:-}" ]; then
    echo "Deleting IoT Topic Rule: $RULE_NAME"
    awslocal iot delete-topic-rule --rule-name "$RULE_NAME" || true
fi

if [ -n "${POLICY_NAME:-}" ]; then
    echo "Deleting IoT Policy: $POLICY_NAME"
    awslocal iot delete-policy --policy-name "$POLICY_NAME" || true
fi

if [ -n "${THING_NAME:-}" ]; then
    echo "Deleting IoT Thing: $THING_NAME"
    awslocal iot delete-thing --thing-name "$THING_NAME" || true
fi

# Clean up .env file
rm -f "$SCRIPT_DIR/.env"

echo "Teardown complete!"
