"""
Tests for athena-s3-queries sample (Python).

Run with:
    uv run pytest samples/athena-s3-queries/python/ -v
"""

from pathlib import Path

import pytest

# Sample configuration
SAMPLE_NAME = "athena-s3-queries"
LANGUAGE = "python"
SAMPLE_DIR = Path(__file__).parent


def get_iac_methods():
    """Discover available IaC methods for this sample."""
    methods = []
    if (SAMPLE_DIR / "scripts" / "deploy.sh").exists():
        methods.append("scripts")
    for iac in ["terraform", "cloudformation", "cdk"]:
        if (SAMPLE_DIR / iac / "deploy.sh").exists():
            methods.append(iac)
    return methods


@pytest.fixture(scope="module", params=get_iac_methods())
def deployed_env(request, wait_for):
    """Deploy the sample with each IaC method and return env vars."""
    from conftest import run_deploy, get_deploy_script_path

    iac_method = request.param

    script_path = get_deploy_script_path(SAMPLE_NAME, LANGUAGE, iac_method)
    if not script_path.exists():
        pytest.skip(f"Deploy script not found for {iac_method}")

    env = run_deploy(SAMPLE_NAME, LANGUAGE, iac_method, timeout=600)

    return env


class TestAthenaS3Queries:
    """Test suite for Athena S3 Queries sample."""

    def test_s3_bucket_exists(self, deployed_env, aws_clients):
        """S3 bucket should exist."""
        bucket_name = deployed_env["BUCKET"]
        response = aws_clients.s3_client.head_bucket(Bucket=bucket_name)
        assert response["ResponseMetadata"]["HTTPStatusCode"] == 200

    def test_data_uploaded(self, deployed_env, aws_clients):
        """Test data CSV should be uploaded to S3."""
        bucket_name = deployed_env["BUCKET"]
        response = aws_clients.s3_client.list_objects_v2(
            Bucket=bucket_name, Prefix="data/"
        )
        objects = response.get("Contents", [])

        assert len(objects) > 0, "No data files found in bucket"
        keys = [obj["Key"] for obj in objects]
        assert any("data.csv" in key for key in keys), "data.csv not found"

    def test_glue_database_exists(self, deployed_env, aws_clients):
        """Glue database should exist."""
        database_name = deployed_env["DATABASE"]
        response = aws_clients.glue_client.get_database(Name=database_name)
        assert response["Database"]["Name"] == database_name

    def test_glue_table_exists(self, deployed_env, aws_clients):
        """Glue table should exist with correct schema."""
        database_name = deployed_env["DATABASE"]
        table_name = deployed_env["TABLE"]

        response = aws_clients.glue_client.get_table(
            DatabaseName=database_name, Name=table_name
        )
        table = response["Table"]

        assert table["Name"] == table_name

        # Check columns
        columns = table["StorageDescriptor"]["Columns"]
        column_names = [col["Name"] for col in columns]

        expected_columns = [
            "id", "first_name", "last_name", "email",
            "gender", "is_active", "joined_date"
        ]
        for col in expected_columns:
            assert col in column_names, f"Column {col} not found"

    def test_athena_query_gender_count(self, deployed_env, aws_clients, wait_for):
        """Athena query should return correct gender counts."""
        database_name = deployed_env["DATABASE"]
        s3_output = deployed_env["S3_OUTPUT"]

        # Run the query
        query = "SELECT gender, COUNT(1) as count FROM test_table1 GROUP BY gender"
        response = aws_clients.athena_client.start_query_execution(
            QueryString=query,
            QueryExecutionContext={"Database": database_name},
            ResultConfiguration={"OutputLocation": s3_output},
        )
        query_id = response["QueryExecutionId"]

        # Wait for query to complete
        result = wait_for.athena_query_complete(query_id)
        state = result["QueryExecution"]["Status"]["State"]
        assert state == "SUCCEEDED", f"Query failed with state: {state}"

        # Get results
        results = aws_clients.athena_client.get_query_results(
            QueryExecutionId=query_id
        )

        rows = results["ResultSet"]["Rows"]
        # First row is header
        assert len(rows) >= 3, "Expected header + 2 data rows (Male/Female)"

        # Parse results
        gender_counts = {}
        for row in rows[1:]:  # Skip header
            gender = row["Data"][0]["VarCharValue"]
            count = int(row["Data"][1]["VarCharValue"])
            gender_counts[gender] = count

        # Data has 49 males, 51 females
        assert "Male" in gender_counts, "Male count not found"
        assert "Female" in gender_counts, "Female count not found"
        assert gender_counts["Male"] == 49, f"Expected 49 males, got {gender_counts['Male']}"
        assert gender_counts["Female"] == 51, f"Expected 51 females, got {gender_counts['Female']}"

    def test_athena_query_total_count(self, deployed_env, aws_clients, wait_for):
        """Athena query should return correct total count."""
        database_name = deployed_env["DATABASE"]
        s3_output = deployed_env["S3_OUTPUT"]

        query = "SELECT COUNT(*) as total FROM test_table1"
        response = aws_clients.athena_client.start_query_execution(
            QueryString=query,
            QueryExecutionContext={"Database": database_name},
            ResultConfiguration={"OutputLocation": s3_output},
        )
        query_id = response["QueryExecutionId"]

        result = wait_for.athena_query_complete(query_id)
        state = result["QueryExecution"]["Status"]["State"]
        assert state == "SUCCEEDED", f"Query failed with state: {state}"

        results = aws_clients.athena_client.get_query_results(
            QueryExecutionId=query_id
        )

        rows = results["ResultSet"]["Rows"]
        assert len(rows) >= 2, "Expected header + 1 data row"

        total = int(rows[1]["Data"][0]["VarCharValue"])
        assert total == 100, f"Expected 100 total rows, got {total}"

    def test_athena_query_filter(self, deployed_env, aws_clients, wait_for):
        """Athena query with WHERE clause should work."""
        database_name = deployed_env["DATABASE"]
        s3_output = deployed_env["S3_OUTPUT"]

        query = "SELECT COUNT(*) as count FROM test_table1 WHERE is_active = true"
        response = aws_clients.athena_client.start_query_execution(
            QueryString=query,
            QueryExecutionContext={"Database": database_name},
            ResultConfiguration={"OutputLocation": s3_output},
        )
        query_id = response["QueryExecutionId"]

        result = wait_for.athena_query_complete(query_id)
        state = result["QueryExecution"]["Status"]["State"]
        assert state == "SUCCEEDED", f"Query failed with state: {state}"

        results = aws_clients.athena_client.get_query_results(
            QueryExecutionId=query_id
        )

        rows = results["ResultSet"]["Rows"]
        count = int(rows[1]["Data"][0]["VarCharValue"])
        # Count should be between 1 and 99 (at least some active users)
        assert 1 <= count <= 99, f"Unexpected active user count: {count}"

    def test_athena_select_specific_columns(self, deployed_env, aws_clients, wait_for):
        """Athena query selecting specific columns should work."""
        database_name = deployed_env["DATABASE"]
        s3_output = deployed_env["S3_OUTPUT"]

        query = "SELECT first_name, last_name, email FROM test_table1 LIMIT 5"
        response = aws_clients.athena_client.start_query_execution(
            QueryString=query,
            QueryExecutionContext={"Database": database_name},
            ResultConfiguration={"OutputLocation": s3_output},
        )
        query_id = response["QueryExecutionId"]

        result = wait_for.athena_query_complete(query_id)
        state = result["QueryExecution"]["Status"]["State"]
        assert state == "SUCCEEDED", f"Query failed with state: {state}"

        results = aws_clients.athena_client.get_query_results(
            QueryExecutionId=query_id
        )

        rows = results["ResultSet"]["Rows"]
        # Header + 5 data rows
        assert len(rows) == 6, f"Expected 6 rows, got {len(rows)}"

        # Check header
        header = [col["VarCharValue"] for col in rows[0]["Data"]]
        assert header == ["first_name", "last_name", "email"]

        # Check that data rows have values
        for row in rows[1:]:
            data = row["Data"]
            assert len(data) == 3
            # Each field should have a value
            for field in data:
                assert "VarCharValue" in field
                assert len(field["VarCharValue"]) > 0
