"""
Tests for lambda-layers sample (JavaScript/Serverless).

Run with:
    uv run pytest samples/lambda-layers/javascript/ -v
"""

import json
from pathlib import Path

import pytest

# Sample configuration
SAMPLE_NAME = "lambda-layers"
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

    if "FUNCTION_NAME" in env:
        wait_for.lambda_active(env["FUNCTION_NAME"])

    return env


class TestLambdaLayers:
    """Test suite for Lambda Layers sample."""

    def test_function_exists(self, deployed_env, aws_clients):
        """Lambda function should exist and be active."""
        function_name = deployed_env["FUNCTION_NAME"]
        response = aws_clients.lambda_client.get_function(FunctionName=function_name)
        assert response["Configuration"]["State"] == "Active"

    def test_layer_attached(self, deployed_env, aws_clients):
        """Lambda should have a layer attached."""
        function_name = deployed_env["FUNCTION_NAME"]
        response = aws_clients.lambda_client.get_function(FunctionName=function_name)
        layers = response["Configuration"].get("Layers", [])
        assert len(layers) > 0, "No layers attached to function"

    def test_function_invocation(self, deployed_env, invoke_lambda):
        """Lambda should invoke successfully."""
        function_name = deployed_env["FUNCTION_NAME"]
        response = invoke_lambda(function_name, {})
        assert response.get("statusCode") == 200

    def test_layer_code_works(self, deployed_env, invoke_lambda):
        """Lambda should use layer code correctly."""
        function_name = deployed_env["FUNCTION_NAME"]
        response = invoke_lambda(function_name, {})

        body = response.get("body")
        if isinstance(body, str):
            body = json.loads(body)

        assert body.get("message") == "Hello from Lambda Layer!"
        assert body.get("layerWorking") is True

    def test_no_import_errors(self, deployed_env, invoke_lambda):
        """Lambda should not have import/module errors."""
        function_name = deployed_env["FUNCTION_NAME"]
        response = invoke_lambda(function_name, {})

        # Check for Lambda error indicators
        assert "errorType" not in response
        assert "errorMessage" not in response
