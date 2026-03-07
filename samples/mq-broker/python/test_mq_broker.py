"""
Tests for mq-broker sample (Python).

Run with:
    uv run pytest samples/mq-broker/python/ -v
"""

import requests
from pathlib import Path

import pytest

# Sample configuration
SAMPLE_NAME = "mq-broker"
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


class TestMQBroker:
    """Test suite for MQ Broker sample."""

    def test_broker_exists(self, deployed_env, aws_clients):
        """MQ broker should exist."""
        broker_id = deployed_env["BROKER_ID"]
        response = aws_clients.mq_client.describe_broker(BrokerId=broker_id)

        assert response["BrokerId"] == broker_id
        assert response["BrokerState"] in ["RUNNING", "CREATION_IN_PROGRESS"]

    def test_broker_name(self, deployed_env, aws_clients):
        """Broker should have the expected name."""
        broker_id = deployed_env["BROKER_ID"]
        broker_name = deployed_env["BROKER_NAME"]

        response = aws_clients.mq_client.describe_broker(BrokerId=broker_id)
        assert response["BrokerName"] == broker_name

    def test_broker_engine_type(self, deployed_env, aws_clients):
        """Broker should be ActiveMQ."""
        broker_id = deployed_env["BROKER_ID"]

        response = aws_clients.mq_client.describe_broker(BrokerId=broker_id)
        assert response["EngineType"] == "ACTIVEMQ"

    def test_broker_deployment_mode(self, deployed_env, aws_clients):
        """Broker should be in single instance mode."""
        broker_id = deployed_env["BROKER_ID"]

        response = aws_clients.mq_client.describe_broker(BrokerId=broker_id)
        assert response["DeploymentMode"] == "SINGLE_INSTANCE"

    def test_broker_has_console_url(self, deployed_env, aws_clients):
        """Broker should have a console URL."""
        broker_id = deployed_env["BROKER_ID"]

        response = aws_clients.mq_client.describe_broker(BrokerId=broker_id)
        instances = response.get("BrokerInstances", [])

        assert len(instances) > 0, "No broker instances found"
        console_url = instances[0].get("ConsoleURL", "")
        assert console_url, "Console URL is empty"
        assert console_url.startswith("http"), f"Invalid console URL: {console_url}"

    def test_broker_user_exists(self, deployed_env, aws_clients):
        """Broker should have the admin user."""
        broker_id = deployed_env["BROKER_ID"]
        username = deployed_env["USERNAME"]

        response = aws_clients.mq_client.describe_user(
            BrokerId=broker_id,
            Username=username
        )

        assert response["Username"] == username
        assert response["ConsoleAccess"] is True

    def test_send_message_to_queue(self, deployed_env):
        """Should be able to send a message to a queue via HTTP API."""
        console_url = deployed_env.get("CONSOLE_URL", "")
        username = deployed_env["USERNAME"]
        password = deployed_env["PASSWORD"]

        if not console_url:
            pytest.skip("Console URL not available")

        # ActiveMQ REST API endpoint
        # Format: http://host:port/api/message?destination=queue://name
        api_url = f"{console_url}/api/message"

        response = requests.post(
            api_url,
            params={"destination": "queue://test.queue"},
            data={"body": "test message"},
            auth=(username, password),
            timeout=10,
        )

        # ActiveMQ returns 200 on success
        assert response.status_code == 200, f"Failed to send message: {response.text}"

    def test_list_brokers(self, deployed_env, aws_clients):
        """Broker should appear in list of brokers."""
        broker_id = deployed_env["BROKER_ID"]

        response = aws_clients.mq_client.list_brokers()
        broker_ids = [b["BrokerId"] for b in response.get("BrokerSummaries", [])]

        assert broker_id in broker_ids, f"Broker {broker_id} not found in list"
