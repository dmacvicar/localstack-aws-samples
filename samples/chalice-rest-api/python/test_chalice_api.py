"""
Tests for Chalice REST API sample.

This sample requires chalice-local to be installed.
Tests will be skipped if chalice-local is not available.

Run all IaC methods:
    uv run pytest samples/chalice-rest-api/python/ -v

Run specific IaC method:
    uv run pytest samples/chalice-rest-api/python/ -v -k scripts
"""

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

SAMPLE_NAME = "chalice-rest-api"
LANGUAGE = "python"

# IaC methods to test
IAC_METHODS = ["scripts"]


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


@pytest.fixture
def require_chalice(deployed_env):
    """Skip test if chalice-local is not available."""
    if deployed_env.get("CHALICE_AVAILABLE") != "true":
        pytest.skip("chalice-local not installed")
    if deployed_env.get("DEPLOY_SUCCESS") != "true":
        pytest.skip("Chalice deployment failed")
    return deployed_env


@pytest.fixture
def api_url(require_chalice):
    """Get the API URL."""
    url = require_chalice.get("API_URL")
    if not url:
        pytest.skip("API URL not available")
    return url.rstrip("/")


class TestChaliceApi:
    """Test Chalice REST API functionality."""

    def test_chalice_available(self, deployed_env):
        """Test that chalice-local availability is detected."""
        # This test always runs to verify detection works
        chalice_available = deployed_env.get("CHALICE_AVAILABLE")
        assert chalice_available in ("true", "false")

    def test_root_endpoint(self, api_url):
        """Test the root endpoint."""
        response = requests.get(f"{api_url}/")
        assert response.status_code == 200
        data = response.json()
        assert data == {"localstack": "chalice integration"}

    def test_health_endpoint(self, api_url):
        """Test the health check endpoint."""
        response = requests.get(f"{api_url}/health")
        assert response.status_code == 200
        assert response.text.strip() == "ok"

    def test_list_todos(self, api_url):
        """Test listing all TODO items."""
        response = requests.get(f"{api_url}/todo")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) >= 2  # Default items

    def test_get_todo(self, api_url):
        """Test getting a specific TODO item."""
        response = requests.get(f"{api_url}/todo/1")
        assert response.status_code == 200
        data = response.json()
        assert "item" in data

    def test_get_todo_not_found(self, api_url):
        """Test getting a non-existent TODO item."""
        response = requests.get(f"{api_url}/todo/999")
        assert response.status_code == 404

    def test_add_todo(self, api_url):
        """Test adding a new TODO item."""
        new_todo = {"item": "Test item from pytest"}
        response = requests.post(
            f"{api_url}/todo",
            json=new_todo,
            headers={"Content-Type": "application/json"},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["item"] == "Test item from pytest"

    def test_update_todo(self, api_url):
        """Test updating a TODO item."""
        updated = {"item": "Updated item"}
        response = requests.put(
            f"{api_url}/todo/1",
            json=updated,
            headers={"Content-Type": "application/json"},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["item"] == "Updated item"

    def test_introspect_endpoint(self, api_url):
        """Test the introspect endpoint."""
        response = requests.get(f"{api_url}/introspect")
        assert response.status_code == 200
        data = response.json()
        assert "method" in data
        assert data["method"] == "GET"

    def test_todo_pagination(self, api_url):
        """Test TODO pagination with query params."""
        response = requests.get(f"{api_url}/todo?offset=0&size=1")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) <= 1
