"""
Tests for Lambda Function URLs sample (JavaScript).

Run all IaC methods:
    uv run pytest samples/lambda-function-urls/javascript/ -v

Run specific IaC method:
    uv run pytest samples/lambda-function-urls/javascript/ -v -k scripts
    uv run pytest samples/lambda-function-urls/javascript/ -v -k terraform
"""

import json
import sys
from pathlib import Path

import pytest
import requests

# Add samples directory to path for conftest imports
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from conftest import (
    AWSClients,
    WaitFor,
    run_deploy,
    get_sample_dir,
)

SAMPLE_NAME = "lambda-function-urls"
LANGUAGE = "javascript"

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

    env = run_deploy(SAMPLE_NAME, LANGUAGE, iac_method, timeout=180)

    # Add IaC method to env for test identification
    env["_IAC_METHOD"] = iac_method

    return env


class TestLambdaFunctionUrls:
    """Test Lambda Function URLs functionality."""

    def test_function_exists(self, deployed_env, aws_clients: AWSClients):
        """Test that the Lambda function was created."""
        function_name = deployed_env.get("FUNCTION_NAME")
        assert function_name, "FUNCTION_NAME should be set"

        response = aws_clients.lambda_client.get_function(FunctionName=function_name)
        assert response["Configuration"]["FunctionName"] == function_name

    def test_function_runtime(self, deployed_env, aws_clients: AWSClients):
        """Test that the function uses Node.js runtime."""
        function_name = deployed_env.get("FUNCTION_NAME")

        response = aws_clients.lambda_client.get_function(FunctionName=function_name)
        runtime = response["Configuration"]["Runtime"]
        assert runtime.startswith("nodejs")

    def test_function_url_exists(self, deployed_env):
        """Test that the function URL was created."""
        function_url = deployed_env.get("FUNCTION_URL")
        assert function_url, "FUNCTION_URL should be set"
        assert function_url.startswith("http")

    def test_function_url_responds(self, deployed_env):
        """Test that the function URL returns a response."""
        function_url = deployed_env.get("FUNCTION_URL")

        response = requests.post(
            function_url,
            json={"num1": 5, "num2": 3},
            timeout=30,
        )
        assert response.status_code == 200

    def test_function_url_calculates_product(self, deployed_env):
        """Test that the function correctly calculates the product."""
        function_url = deployed_env.get("FUNCTION_URL")

        response = requests.post(
            function_url,
            json={"num1": 7, "num2": 8},
            timeout=30,
        )
        assert response.status_code == 200

        body = response.json()
        assert body["result"] == 56
        assert "56" in body["message"]

    def test_function_url_handles_decimals(self, deployed_env):
        """Test that the function handles decimal numbers."""
        function_url = deployed_env.get("FUNCTION_URL")

        response = requests.post(
            function_url,
            json={"num1": 2.5, "num2": 4},
            timeout=30,
        )
        assert response.status_code == 200

        body = response.json()
        assert body["result"] == 10.0

    def test_direct_invoke(self, deployed_env, aws_clients: AWSClients):
        """Test direct Lambda invocation."""
        function_name = deployed_env.get("FUNCTION_NAME")

        response = aws_clients.lambda_client.invoke(
            FunctionName=function_name,
            Payload=json.dumps({"num1": 10, "num2": 10}),
        )

        payload = json.loads(response["Payload"].read())
        body = json.loads(payload["body"])
        assert body["result"] == 100
