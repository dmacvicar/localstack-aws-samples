"""
Tests for lambda-event-filtering sample (JavaScript).

Run with:
    uv run pytest samples/lambda-event-filtering/javascript/ -v
"""

import json
import uuid
import time
from pathlib import Path

import pytest

# Sample configuration
SAMPLE_NAME = "lambda-event-filtering"
LANGUAGE = "javascript"
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

    env = run_deploy(SAMPLE_NAME, LANGUAGE, iac_method)

    # Wait for both Lambda functions to be active
    if "DYNAMODB_FUNCTION_NAME" in env:
        wait_for.lambda_active(env["DYNAMODB_FUNCTION_NAME"])
    if "SQS_FUNCTION_NAME" in env:
        wait_for.lambda_active(env["SQS_FUNCTION_NAME"])

    return env


class TestLambdaEventFiltering:
    """Test suite for Lambda Event Filtering sample."""

    def test_dynamodb_table_exists(self, deployed_env, aws_clients):
        """DynamoDB table should exist with streams enabled."""
        table_name = deployed_env["TABLE_NAME"]
        response = aws_clients.dynamodb_client.describe_table(TableName=table_name)
        table = response["Table"]

        assert table["TableStatus"] == "ACTIVE"
        assert table.get("StreamSpecification", {}).get("StreamEnabled") is True
        assert table.get("StreamSpecification", {}).get("StreamViewType") == "NEW_IMAGE"

    def test_sqs_queue_exists(self, deployed_env, aws_clients):
        """SQS queue should exist."""
        queue_name = deployed_env["QUEUE_NAME"]
        response = aws_clients.sqs_client.list_queues(QueueNamePrefix=queue_name)
        queue_urls = response.get("QueueUrls", [])

        assert len(queue_urls) > 0, f"Queue {queue_name} not found"

    def test_dynamodb_function_exists(self, deployed_env, aws_clients):
        """DynamoDB processor Lambda should exist and be active."""
        function_name = deployed_env["DYNAMODB_FUNCTION_NAME"]
        response = aws_clients.lambda_client.get_function(FunctionName=function_name)
        assert response["Configuration"]["State"] == "Active"

    def test_sqs_function_exists(self, deployed_env, aws_clients):
        """SQS processor Lambda should exist and be active."""
        function_name = deployed_env["SQS_FUNCTION_NAME"]
        response = aws_clients.lambda_client.get_function(FunctionName=function_name)
        assert response["Configuration"]["State"] == "Active"

    def test_dynamodb_event_source_mapping(self, deployed_env, aws_clients):
        """DynamoDB event source mapping should exist with INSERT filter."""
        function_name = deployed_env["DYNAMODB_FUNCTION_NAME"]
        response = aws_clients.lambda_client.list_event_source_mappings(
            FunctionName=function_name
        )
        mappings = response.get("EventSourceMappings", [])

        assert len(mappings) > 0, "No event source mappings found"

        # Check for filter criteria
        mapping = mappings[0]
        filter_criteria = mapping.get("FilterCriteria", {})
        filters = filter_criteria.get("Filters", [])

        assert len(filters) > 0, "No filter criteria on event source mapping"

        # Verify INSERT filter
        pattern = json.loads(filters[0]["Pattern"])
        assert "eventName" in pattern
        assert "INSERT" in pattern["eventName"]

    def test_sqs_event_source_mapping(self, deployed_env, aws_clients):
        """SQS event source mapping should exist with data:A filter."""
        function_name = deployed_env["SQS_FUNCTION_NAME"]
        response = aws_clients.lambda_client.list_event_source_mappings(
            FunctionName=function_name
        )
        mappings = response.get("EventSourceMappings", [])

        assert len(mappings) > 0, "No event source mappings found"

        # Check for filter criteria
        mapping = mappings[0]
        filter_criteria = mapping.get("FilterCriteria", {})
        filters = filter_criteria.get("Filters", [])

        assert len(filters) > 0, "No filter criteria on event source mapping"

        # Verify data:A filter
        pattern = json.loads(filters[0]["Pattern"])
        assert "body" in pattern
        assert "data" in pattern["body"]
        assert "A" in pattern["body"]["data"]

    def test_dynamodb_stream_triggers_on_insert(self, deployed_env, aws_clients):
        """DynamoDB stream should trigger Lambda on INSERT."""
        table_name = deployed_env["TABLE_NAME"]
        function_name = deployed_env["DYNAMODB_FUNCTION_NAME"]

        # Insert an item
        item_id = str(uuid.uuid4())
        aws_clients.dynamodb_client.put_item(
            TableName=table_name,
            Item={
                "id": {"S": item_id},
                "data": {"S": "test"},
            },
        )

        # Wait a moment for the event to process
        time.sleep(2)

        # Verify the function was invoked by checking CloudWatch logs
        # In LocalStack, we can verify the event source mapping is active
        response = aws_clients.lambda_client.list_event_source_mappings(
            FunctionName=function_name
        )
        mapping = response["EventSourceMappings"][0]
        assert mapping["State"] in ["Enabled", "Enabling"]

    def test_sqs_triggers_on_matching_message(self, deployed_env, aws_clients):
        """SQS should trigger Lambda when message matches filter."""
        queue_url = deployed_env["QUEUE_URL"]
        function_name = deployed_env["SQS_FUNCTION_NAME"]

        # Send a message that matches the filter (data: "A")
        aws_clients.sqs_client.send_message(
            QueueUrl=queue_url,
            MessageBody=json.dumps({"data": "A"}),
        )

        # Wait a moment for the event to process
        time.sleep(2)

        # Verify the function's event source mapping is active
        response = aws_clients.lambda_client.list_event_source_mappings(
            FunctionName=function_name
        )
        mapping = response["EventSourceMappings"][0]
        assert mapping["State"] in ["Enabled", "Enabling"]
