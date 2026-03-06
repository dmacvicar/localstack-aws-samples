#!/bin/bash
set -euo pipefail

# Setup script for test badges gist
# This creates a new gist with placeholder badge data for all samples

# Requires: gh CLI authenticated, or GITHUB_TOKEN environment variable

echo "Creating test badges gist..."

# Create temporary directory for badge files
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Create placeholder badge for each sample
samples=(
    "lambda-function-urls-python"
    "lambda-function-urls-javascript"
    "stepfunctions-lambda-python"
    "web-app-dynamodb-python"
    "lambda-s3-http-python"
    "lambda-cloudfront-python"
    "web-app-rds-python"
    "apigw-custom-domain-python"
    "ecs-ecr-app-python"
    "lambda-container-image-python"
    "apigw-websockets-javascript"
    "lambda-layers-javascript"
    "lambda-event-filtering-javascript"
    "lambda-xray-python"
    "codecommit-git-repo-python"
    "iot-basics-python"
    "transfer-ftp-s3-python"
    "glacier-s3-select-python"
    "rds-failover-test-python"
)

for sample in "${samples[@]}"; do
    cat > "$TEMP_DIR/${sample}.json" << EOF
{
  "schemaVersion": 1,
  "label": "tests",
  "message": "pending",
  "color": "lightgrey",
  "passed": 0,
  "failed": 0,
  "total": 0
}
EOF
done

# Also create the all-results.json
echo '{}' > "$TEMP_DIR/all-results.json"

echo "Created ${#samples[@]} badge files"

# Create the gist
echo ""
echo "Creating gist with gh CLI..."
cd "$TEMP_DIR"

GIST_URL=$(gh gist create *.json --public --desc "LocalStack Pro Samples Test Badges" 2>&1 | tail -1)
GIST_ID=$(echo "$GIST_URL" | rev | cut -d'/' -f1 | rev)

echo ""
echo "=========================================="
echo "Gist created successfully!"
echo "=========================================="
echo ""
echo "Gist URL: $GIST_URL"
echo "Gist ID:  $GIST_ID"
echo ""
echo "Next steps:"
echo ""
echo "1. Add these secrets to your GitHub repository:"
echo "   - GIST_TOKEN: A personal access token with 'gist' scope"
echo "   - TEST_BADGES_GIST_ID: $GIST_ID"
echo ""
echo "2. Update README.md to replace 'localstack-samples' with your GitHub username"
echo "   and 'TEST_BADGES_GIST_ID' with: $GIST_ID"
echo ""
echo "3. Run the CI workflow to populate the badges with real test results"
echo ""
