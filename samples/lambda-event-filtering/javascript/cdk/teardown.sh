#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
STACK_NAME="LambdaEventFilteringStack"

echo "Tearing down Lambda Event Filtering Sample via CDK"

cd "$SCRIPT_DIR"

if command -v cdklocal &> /dev/null; then
    CDK="cdklocal"
else
    CDK="cdk"
fi

echo "Destroying CDK stack..."
$CDK destroy --force 2>/dev/null || true

# Cleanup
rm -f "$PROJECT_DIR/scripts/.env"
rm -f cdk-outputs.json
rm -rf cdk.out

echo "Teardown complete!"
