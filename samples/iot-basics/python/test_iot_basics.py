"""
Tests for iot-basics sample (Python).

Run with:
    uv run pytest samples/iot-basics/python/ -v
"""

from pathlib import Path

import pytest

# Sample configuration
SAMPLE_NAME = "iot-basics"
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

    env = run_deploy(SAMPLE_NAME, LANGUAGE, iac_method, timeout=300)

    return env


class TestIoTBasics:
    """Test suite for IoT Basics sample."""

    def test_thing_exists(self, deployed_env, aws_clients):
        """IoT Thing should exist."""
        thing_name = deployed_env["THING_NAME"]
        response = aws_clients.iot_client.describe_thing(thingName=thing_name)

        assert response["thingName"] == thing_name

    def test_thing_has_attributes(self, deployed_env, aws_clients):
        """IoT Thing should have expected attributes."""
        thing_name = deployed_env["THING_NAME"]
        response = aws_clients.iot_client.describe_thing(thingName=thing_name)

        attributes = response.get("attributes", {})
        assert attributes.get("env") == "test"
        assert attributes.get("version") == "1.0"

    def test_policy_exists(self, deployed_env, aws_clients):
        """IoT Policy should exist."""
        policy_name = deployed_env["POLICY_NAME"]
        response = aws_clients.iot_client.get_policy(policyName=policy_name)

        assert response["policyName"] == policy_name

    def test_policy_has_document(self, deployed_env, aws_clients):
        """IoT Policy should have a policy document."""
        policy_name = deployed_env["POLICY_NAME"]
        response = aws_clients.iot_client.get_policy(policyName=policy_name)

        policy_doc = response.get("policyDocument")
        assert policy_doc is not None
        assert "iot:Connect" in policy_doc or "Connect" in policy_doc

    def test_topic_rule_exists(self, deployed_env, aws_clients):
        """IoT Topic Rule should exist."""
        rule_name = deployed_env["RULE_NAME"]
        response = aws_clients.iot_client.get_topic_rule(ruleName=rule_name)

        assert response["rule"]["ruleName"] == rule_name

    def test_topic_rule_sql(self, deployed_env, aws_clients):
        """IoT Topic Rule should have SQL query."""
        rule_name = deployed_env["RULE_NAME"]
        response = aws_clients.iot_client.get_topic_rule(ruleName=rule_name)

        sql = response["rule"].get("sql", "")
        assert "iot/sensor" in sql or "SELECT" in sql

    def test_list_things(self, deployed_env, aws_clients):
        """Thing should appear in list of things."""
        thing_name = deployed_env["THING_NAME"]
        response = aws_clients.iot_client.list_things()
        thing_names = [t["thingName"] for t in response.get("things", [])]

        assert thing_name in thing_names

    def test_list_policies(self, deployed_env, aws_clients):
        """Policy should appear in list of policies."""
        policy_name = deployed_env["POLICY_NAME"]
        response = aws_clients.iot_client.list_policies()
        policy_names = [p["policyName"] for p in response.get("policies", [])]

        assert policy_name in policy_names

    def test_iot_endpoint(self, deployed_env, aws_clients):
        """IoT endpoint should be available (if MQTT broker is configured)."""
        try:
            response = aws_clients.iot_client.describe_endpoint()
            endpoint = response.get("endpointAddress", "")
            assert endpoint, "IoT endpoint not available"
            assert ":" in endpoint, f"Invalid endpoint format: {endpoint}"
        except Exception as e:
            if "broker_manager" in str(e):
                pytest.skip("IoT MQTT broker not available in this LocalStack configuration")
            raise
