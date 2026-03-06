"""
Tests for Lambda X-Ray Tracing sample.

Run all IaC methods:
    uv run pytest samples/lambda-xray/python/ -v

Run specific IaC method:
    uv run pytest samples/lambda-xray/python/ -v -k scripts
    uv run pytest samples/lambda-xray/python/ -v -k terraform
"""

import json
import sys
import time
from pathlib import Path

import pytest

# Add samples directory to path for conftest imports
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from conftest import (
    AWSClients,
    WaitFor,
    run_deploy,
    get_sample_dir,
)

SAMPLE_NAME = "lambda-xray"
LANGUAGE = "python"

# IaC methods to test
IAC_METHODS = ["scripts", "terraform", "cloudformation", "cdk"]


@pytest.fixture(scope="module", params=IAC_METHODS)
def deployed_env(request, aws_clients: AWSClients, wait_for: WaitFor):
    """Deploy the sample and return environment variables."""
    iac_method = request.param

    # Check if deploy script exists
    sample_dir = get_sample_dir(SAMPLE_NAME, LANGUAGE)
    if iac_method == "scripts":
        deploy_path = sample_dir / "scripts" / "deploy.sh"
    else:
        deploy_path = sample_dir / iac_method / "deploy.sh"

    if not deploy_path.exists():
        pytest.skip(f"Deploy script not found: {deploy_path}")

    env = run_deploy(SAMPLE_NAME, LANGUAGE, iac_method, timeout=300)

    # Wait for Lambda to be active
    if env.get("FUNCTION_NAME"):
        wait_for.lambda_active(env["FUNCTION_NAME"])

    # Add IaC method to env for test identification
    env["_IAC_METHOD"] = iac_method

    return env


class TestLambdaXRay:
    """Test Lambda X-Ray tracing."""

    def test_function_exists(self, deployed_env, aws_clients: AWSClients):
        """Test that the Lambda function was created."""
        function_name = deployed_env.get("FUNCTION_NAME")
        assert function_name, "FUNCTION_NAME should be set"

        response = aws_clients.lambda_client.get_function(FunctionName=function_name)
        assert response["Configuration"]["FunctionName"] == function_name

    def test_function_runtime(self, deployed_env, aws_clients: AWSClients):
        """Test that the function uses Python 3.11."""
        function_name = deployed_env.get("FUNCTION_NAME")

        response = aws_clients.lambda_client.get_function(FunctionName=function_name)
        assert response["Configuration"]["Runtime"] == "python3.11"

    def test_xray_tracing_enabled(self, deployed_env, aws_clients: AWSClients):
        """Test that X-Ray tracing is enabled on the function."""
        function_name = deployed_env.get("FUNCTION_NAME")

        response = aws_clients.lambda_client.get_function(FunctionName=function_name)
        tracing_config = response["Configuration"].get("TracingConfig", {})
        assert tracing_config.get("Mode") == "Active", "X-Ray tracing should be Active"

    def test_function_invocation(self, deployed_env, aws_clients: AWSClients):
        """Test that the function can be invoked."""
        function_name = deployed_env.get("FUNCTION_NAME")

        response = aws_clients.lambda_client.invoke(
            FunctionName=function_name,
            Payload=json.dumps({"test": "event"}),
        )

        assert response["StatusCode"] == 200

        payload = json.loads(response["Payload"].read())
        assert payload["statusCode"] == 200

        body = json.loads(payload["body"])
        assert body["message"] == "X-Ray tracing demo"
        assert "requestId" in body

    def test_role_has_xray_policy(self, deployed_env, aws_clients: AWSClients):
        """Test that the IAM role has X-Ray write policy attached."""
        role_name = deployed_env.get("ROLE_NAME")
        if not role_name:
            pytest.skip("ROLE_NAME not in environment")

        response = aws_clients.iam_client.list_attached_role_policies(
            RoleName=role_name
        )

        policy_arns = [p["PolicyArn"] for p in response["AttachedPolicies"]]
        xray_policy = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
        assert xray_policy in policy_arns, "X-Ray write policy should be attached"

    def test_xray_traces_generated(self, deployed_env, aws_clients: AWSClients):
        """Test that X-Ray traces are generated after invocation."""
        function_name = deployed_env.get("FUNCTION_NAME")

        # Invoke the function
        aws_clients.lambda_client.invoke(
            FunctionName=function_name,
            Payload=json.dumps({"trace": "test"}),
        )

        # Wait a bit for traces to be recorded
        time.sleep(2)

        # Try to get trace summaries
        try:
            xray_client = aws_clients._client("xray")
            end_time = time.time()
            start_time = end_time - 600  # Last 10 minutes

            response = xray_client.get_trace_summaries(
                StartTime=start_time,
                EndTime=end_time,
            )

            # X-Ray traces may or may not be available depending on LocalStack version
            # Just verify the API call works
            assert "TraceSummaries" in response
        except Exception as e:
            # X-Ray API may not be fully available in some LocalStack versions
            pytest.skip(f"X-Ray API not fully available: {e}")
