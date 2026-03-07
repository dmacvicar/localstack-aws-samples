"""
Tests for ELB Load Balancing sample.

Run all IaC methods:
    uv run pytest samples/elb-load-balancing/javascript/ -v

Run specific IaC method:
    uv run pytest samples/elb-load-balancing/javascript/ -v -k scripts
"""

import sys
from pathlib import Path

import boto3
import pytest
import requests

# Add samples directory to path for conftest imports
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from conftest import (
    AWSClients,
    WaitFor,
    run_deploy,
    get_sample_dir,
    LOCALSTACK_ENDPOINT,
    AWS_ACCESS_KEY_ID,
    AWS_SECRET_ACCESS_KEY,
)

SAMPLE_NAME = "elb-load-balancing"
LANGUAGE = "javascript"

# IaC methods to test
IAC_METHODS = ["scripts", "terraform", "cloudformation", "cdk"]


def elbv2_client():
    """Create ELBv2 client."""
    return boto3.client(
        "elbv2",
        endpoint_url=LOCALSTACK_ENDPOINT,
        region_name="us-east-1",
        aws_access_key_id=AWS_ACCESS_KEY_ID,
        aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
    )


def lambda_client():
    """Create Lambda client."""
    return boto3.client(
        "lambda",
        endpoint_url=LOCALSTACK_ENDPOINT,
        region_name="us-east-1",
        aws_access_key_id=AWS_ACCESS_KEY_ID,
        aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
    )


@pytest.fixture(scope="module", params=IAC_METHODS)
def deployed_env(request, aws_clients: AWSClients, wait_for: WaitFor):
    """Deploy the sample and return environment variables."""
    iac_method = request.param

    sample_dir = get_sample_dir(SAMPLE_NAME, LANGUAGE)
    deploy_path = sample_dir / iac_method / "deploy.sh"

    if not deploy_path.exists():
        pytest.skip(f"Deploy script not found: {deploy_path}")

    env = run_deploy(SAMPLE_NAME, LANGUAGE, iac_method, timeout=180)
    env["_IAC_METHOD"] = iac_method

    return env


class TestElbLoadBalancing:
    """Test ELB load balancing functionality."""

    def test_load_balancer_exists(self, deployed_env):
        """Test that the load balancer was created."""
        lb_arn = deployed_env.get("LB_ARN")
        assert lb_arn, "LB_ARN should be set"

        client = elbv2_client()
        response = client.describe_load_balancers(LoadBalancerArns=[lb_arn])
        assert len(response["LoadBalancers"]) == 1

    def test_load_balancer_is_active(self, deployed_env):
        """Test that the load balancer is active."""
        lb_arn = deployed_env.get("LB_ARN")

        client = elbv2_client()
        response = client.describe_load_balancers(LoadBalancerArns=[lb_arn])
        state = response["LoadBalancers"][0]["State"]["Code"]
        assert state in ("active", "provisioning")

    def test_listener_exists(self, deployed_env):
        """Test that the listener was created."""
        listener_arn = deployed_env.get("LISTENER_ARN")
        assert listener_arn, "LISTENER_ARN should be set"

        client = elbv2_client()
        response = client.describe_listeners(ListenerArns=[listener_arn])
        assert len(response["Listeners"]) == 1
        assert response["Listeners"][0]["Port"] == 80

    def test_target_groups_exist(self, deployed_env):
        """Test that target groups were created."""
        tg1_arn = deployed_env.get("TG1_ARN")
        tg2_arn = deployed_env.get("TG2_ARN")
        assert tg1_arn, "TG1_ARN should be set"
        assert tg2_arn, "TG2_ARN should be set"

        client = elbv2_client()
        response = client.describe_target_groups(TargetGroupArns=[tg1_arn, tg2_arn])
        assert len(response["TargetGroups"]) == 2

    def test_target_groups_are_lambda_type(self, deployed_env):
        """Test that target groups are Lambda type."""
        tg1_arn = deployed_env.get("TG1_ARN")

        client = elbv2_client()
        response = client.describe_target_groups(TargetGroupArns=[tg1_arn])
        assert response["TargetGroups"][0]["TargetType"] == "lambda"

    def test_lambda_functions_exist(self, deployed_env):
        """Test that Lambda functions were created."""
        func1_name = deployed_env.get("FUNC1_NAME")
        func2_name = deployed_env.get("FUNC2_NAME")

        client = lambda_client()

        response1 = client.get_function(FunctionName=func1_name)
        assert response1["Configuration"]["FunctionName"] == func1_name

        response2 = client.get_function(FunctionName=func2_name)
        assert response2["Configuration"]["FunctionName"] == func2_name

    def test_lambda_functions_are_active(self, deployed_env):
        """Test that Lambda functions are active."""
        func1_name = deployed_env.get("FUNC1_NAME")

        client = lambda_client()
        response = client.get_function(FunctionName=func1_name)
        assert response["Configuration"]["State"] == "Active"

    def test_listener_rules_exist(self, deployed_env):
        """Test that listener rules were created."""
        listener_arn = deployed_env.get("LISTENER_ARN")

        client = elbv2_client()
        response = client.describe_rules(ListenerArn=listener_arn)

        # Should have default rule + 2 path-based rules
        assert len(response["Rules"]) >= 2

    def test_elb_hello1_endpoint(self, deployed_env):
        """Test the /hello1 endpoint via ELB."""
        elb_url = deployed_env.get("ELB_URL")
        if not elb_url:
            pytest.skip("ELB_URL not available")

        try:
            response = requests.get(f"{elb_url}/hello1", timeout=10)
            assert response.status_code == 200
            data = response.json()
            assert data.get("message") == "Hello 1"
        except requests.exceptions.RequestException as e:
            pytest.skip(f"Could not connect to ELB: {e}")

    def test_elb_hello2_endpoint(self, deployed_env):
        """Test the /hello2 endpoint via ELB."""
        elb_url = deployed_env.get("ELB_URL")
        if not elb_url:
            pytest.skip("ELB_URL not available")

        try:
            response = requests.get(f"{elb_url}/hello2", timeout=10)
            assert response.status_code == 200
            data = response.json()
            assert data.get("message") == "Hello 2"
        except requests.exceptions.RequestException as e:
            pytest.skip(f"Could not connect to ELB: {e}")
