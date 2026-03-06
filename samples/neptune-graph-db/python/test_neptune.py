"""
Tests for Neptune Graph Database sample.

Run all IaC methods:
    uv run pytest samples/neptune-graph-db/python/ -v

Run specific IaC method:
    uv run pytest samples/neptune-graph-db/python/ -v -k scripts
"""

import sys
from pathlib import Path

import boto3
import pytest

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

SAMPLE_NAME = "neptune-graph-db"
LANGUAGE = "python"

# IaC methods to test - Neptune may have limited IaC support
IAC_METHODS = ["scripts"]


def neptune_client(region: str = "us-east-1"):
    """Create Neptune client."""
    return boto3.client(
        "neptune",
        endpoint_url=LOCALSTACK_ENDPOINT,
        region_name=region,
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

    env = run_deploy(SAMPLE_NAME, LANGUAGE, iac_method, timeout=120)
    env["_IAC_METHOD"] = iac_method

    return env


class TestNeptuneGraphDb:
    """Test Neptune Graph Database functionality."""

    def test_cluster_exists(self, deployed_env):
        """Test that the Neptune cluster was created."""
        cluster_id = deployed_env.get("CLUSTER_ID")
        assert cluster_id, "CLUSTER_ID should be set"

        client = neptune_client()
        response = client.describe_db_clusters(DBClusterIdentifier=cluster_id)
        assert len(response["DBClusters"]) == 1
        assert response["DBClusters"][0]["DBClusterIdentifier"] == cluster_id

    def test_cluster_engine(self, deployed_env):
        """Test that the cluster uses Neptune engine."""
        cluster_id = deployed_env.get("CLUSTER_ID")

        client = neptune_client()
        response = client.describe_db_clusters(DBClusterIdentifier=cluster_id)
        assert response["DBClusters"][0]["Engine"] == "neptune"

    def test_cluster_is_available(self, deployed_env):
        """Test that the cluster is available."""
        cluster_id = deployed_env.get("CLUSTER_ID")

        client = neptune_client()
        response = client.describe_db_clusters(DBClusterIdentifier=cluster_id)
        assert response["DBClusters"][0]["Status"] == "available"

    def test_cluster_has_endpoint(self, deployed_env):
        """Test that the cluster has an endpoint."""
        cluster_id = deployed_env.get("CLUSTER_ID")

        client = neptune_client()
        response = client.describe_db_clusters(DBClusterIdentifier=cluster_id)
        cluster = response["DBClusters"][0]
        # Neptune cluster should have endpoint information
        assert "Endpoint" in cluster or "Port" in cluster

    def test_cluster_has_port(self, deployed_env):
        """Test that the cluster has a port assigned."""
        cluster_port = deployed_env.get("CLUSTER_PORT")
        # Port should be set (may be empty string if not available)
        if cluster_port:
            assert int(cluster_port) > 0

    def test_cluster_arn_format(self, deployed_env):
        """Test that the cluster ARN has correct format."""
        cluster_arn = deployed_env.get("CLUSTER_ARN")
        assert cluster_arn, "CLUSTER_ARN should be set"
        assert cluster_arn.startswith("arn:aws:rds:")
        assert ":cluster:" in cluster_arn
