#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"

cd "$SCRIPT_DIR"

echo "Initializing Terraform..."
terraform init -input=false

echo "Applying Terraform configuration..."
terraform apply -auto-approve -input=false

# Extract outputs
BUCKET=$(terraform output -raw bucket_name)
DATABASE=$(terraform output -raw database_name)
TABLE=$(terraform output -raw table_name)
S3_OUTPUT=$(terraform output -raw s3_output)
WORKGROUP=$(terraform output -raw workgroup_name)

# Save configuration for tests (in scripts/.env for consistency)
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
