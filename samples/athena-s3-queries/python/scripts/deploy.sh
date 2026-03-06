#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"

BUCKET="athena-test-$(date +%s)"
DATABASE="test_db"
TABLE="test_table1"
S3_INPUT="s3://$BUCKET/data/data.csv"
S3_OUTPUT="s3://$BUCKET/results"

echo "Creating S3 bucket: $BUCKET"
awslocal s3 mb "s3://$BUCKET"

echo "Uploading test data to S3..."
awslocal s3 cp "$SAMPLE_DIR/data/data.csv" "$S3_INPUT"

# Update SQL files with actual bucket name
CREATE_DB_SQL="CREATE DATABASE IF NOT EXISTS $DATABASE LOCATION 's3://$BUCKET/test_db/'"
CREATE_TABLE_SQL="CREATE EXTERNAL TABLE IF NOT EXISTS $DATABASE.$TABLE (
  id INT,
  first_name STRING,
  last_name STRING,
  email STRING,
  gender STRING,
  is_active BOOLEAN,
  joined_date STRING)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION 's3a://$BUCKET/data/'
TBLPROPERTIES ('skip.header.line.count'='1')"

wait_for_query() {
    local query_id=$1
    local max_attempts=60
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        status=$(awslocal athena get-query-execution --query-execution-id "$query_id" | jq -r '.QueryExecution.Status.State')
        echo "Query $query_id status: $status"

        if [ "$status" = "SUCCEEDED" ]; then
            return 0
        elif [ "$status" = "FAILED" ] || [ "$status" = "CANCELLED" ]; then
            echo "Query failed with status: $status"
            awslocal athena get-query-execution --query-execution-id "$query_id" | jq '.QueryExecution.Status'
            return 1
        fi

        sleep 3
        attempt=$((attempt + 1))
    done

    echo "Query did not complete in time"
    return 1
}

echo "Creating Athena database..."
QUERY_ID=$(awslocal athena start-query-execution \
    --query-string "$CREATE_DB_SQL" \
    --result-configuration "OutputLocation=$S3_OUTPUT" \
    | jq -r '.QueryExecutionId')
echo "Database creation query ID: $QUERY_ID"
wait_for_query "$QUERY_ID"

echo "Creating Athena table..."
QUERY_ID=$(awslocal athena start-query-execution \
    --query-string "$CREATE_TABLE_SQL" \
    --query-execution-context "Database=$DATABASE" \
    --result-configuration "OutputLocation=$S3_OUTPUT" \
    | jq -r '.QueryExecutionId')
echo "Table creation query ID: $QUERY_ID"
wait_for_query "$QUERY_ID"

# Save configuration for tests
cat > "$SCRIPT_DIR/.env" << EOF
BUCKET=$BUCKET
DATABASE=$DATABASE
TABLE=$TABLE
S3_OUTPUT=$S3_OUTPUT
EOF

echo ""
echo "Deployment complete!"
echo "Bucket: $BUCKET"
echo "Database: $DATABASE"
echo "Table: $TABLE"
