#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
else
    echo "No .env file found. Nothing to tear down."
    exit 0
fi

echo "Cleaning up Athena resources..."

# Drop table and database
if [ -n "${DATABASE:-}" ] && [ -n "${TABLE:-}" ]; then
    echo "Dropping table $DATABASE.$TABLE..."
    awslocal athena start-query-execution \
        --query-string "DROP TABLE IF EXISTS $DATABASE.$TABLE" \
        --query-execution-context "Database=$DATABASE" \
        --result-configuration "OutputLocation=${S3_OUTPUT:-s3://$BUCKET/results}" || true

    sleep 2

    echo "Dropping database $DATABASE..."
    awslocal athena start-query-execution \
        --query-string "DROP DATABASE IF EXISTS $DATABASE" \
        --result-configuration "OutputLocation=${S3_OUTPUT:-s3://$BUCKET/results}" || true
fi

# Delete S3 bucket
if [ -n "${BUCKET:-}" ]; then
    echo "Deleting S3 bucket: $BUCKET"
    awslocal s3 rb "s3://$BUCKET" --force || true
fi

# Clean up .env file
rm -f "$SCRIPT_DIR/.env"

echo "Teardown complete!"
