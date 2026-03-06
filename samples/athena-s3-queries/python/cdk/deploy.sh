#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"

cd "$SCRIPT_DIR"

echo "Installing CDK dependencies..."
pip install -q -r requirements.txt

echo "Bootstrapping CDK (if needed)..."
cdklocal bootstrap --quiet 2>/dev/null || true

echo "Deploying CDK stack..."
cdklocal deploy --require-approval never --outputs-file outputs.json

# Extract outputs
BUCKET=$(jq -r '.AthenaS3QueriesStack.BucketName' outputs.json)
DATABASE=$(jq -r '.AthenaS3QueriesStack.DatabaseName' outputs.json)
TABLE=$(jq -r '.AthenaS3QueriesStack.TableName' outputs.json)
S3_OUTPUT=$(jq -r '.AthenaS3QueriesStack.S3Output' outputs.json)
WORKGROUP=$(jq -r '.AthenaS3QueriesStack.WorkgroupName' outputs.json)

# Save configuration for tests
cat > "$SAMPLE_DIR/scripts/.env" << EOF
BUCKET=$BUCKET
DATABASE=$DATABASE
TABLE=$TABLE
S3_OUTPUT=$S3_OUTPUT
WORKGROUP=$WORKGROUP
EOF

echo ""
echo "Deployment complete!"
echo "Bucket: $BUCKET"
echo "Database: $DATABASE"
echo "Table: $TABLE"
echo "Workgroup: $WORKGROUP"
