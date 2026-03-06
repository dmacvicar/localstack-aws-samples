"""
Tests for Cognito JWT sample.

This sample tests Cognito User Pools and JWT authentication.
Email verification tests require SMTP configuration and will be skipped otherwise.

Run all IaC methods:
    uv run pytest samples/cognito-jwt/python/ -v

Run specific IaC method:
    uv run pytest samples/cognito-jwt/python/ -v -k scripts
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

SAMPLE_NAME = "cognito-jwt"
LANGUAGE = "python"

# IaC methods to test
IAC_METHODS = ["scripts"]


def cognito_client():
    """Create Cognito Identity Provider client."""
    return boto3.client(
        "cognito-idp",
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

    env = run_deploy(SAMPLE_NAME, LANGUAGE, iac_method, timeout=60)
    env["_IAC_METHOD"] = iac_method

    return env


@pytest.fixture
def require_smtp(deployed_env):
    """Skip test if SMTP is not configured."""
    if deployed_env.get("SMTP_CONFIGURED") != "true":
        pytest.skip("SMTP not configured (start LocalStack with SMTP_HOST)")
    return deployed_env


class TestCognitoJwt:
    """Test Cognito User Pool and JWT functionality."""

    def test_user_pool_exists(self, deployed_env):
        """Test that the User Pool was created."""
        pool_id = deployed_env.get("POOL_ID")
        assert pool_id, "POOL_ID should be set"

        client = cognito_client()
        response = client.describe_user_pool(UserPoolId=pool_id)
        assert response["UserPool"]["Id"] == pool_id

    def test_user_pool_client_exists(self, deployed_env):
        """Test that the User Pool Client was created."""
        pool_id = deployed_env.get("POOL_ID")
        client_id = deployed_env.get("CLIENT_ID")
        assert client_id, "CLIENT_ID should be set"

        client = cognito_client()
        response = client.describe_user_pool_client(
            UserPoolId=pool_id,
            ClientId=client_id,
        )
        assert response["UserPoolClient"]["ClientId"] == client_id

    def test_admin_user_exists(self, deployed_env):
        """Test that the admin user was created."""
        pool_id = deployed_env.get("POOL_ID")
        admin_user = deployed_env.get("ADMIN_USER")

        client = cognito_client()
        response = client.admin_get_user(
            UserPoolId=pool_id,
            Username=admin_user,
        )
        assert response["Username"] == admin_user

    def test_admin_user_is_confirmed(self, deployed_env):
        """Test that the admin user is confirmed."""
        pool_id = deployed_env.get("POOL_ID")
        admin_user = deployed_env.get("ADMIN_USER")

        client = cognito_client()
        response = client.admin_get_user(
            UserPoolId=pool_id,
            Username=admin_user,
        )
        assert response["UserStatus"] == "CONFIRMED"

    def test_admin_auth_returns_tokens(self, deployed_env):
        """Test that admin authentication returns JWT tokens."""
        pool_id = deployed_env.get("POOL_ID")
        client_id = deployed_env.get("CLIENT_ID")
        admin_user = deployed_env.get("ADMIN_USER")
        password = deployed_env.get("TEST_PASSWORD")

        client = cognito_client()
        response = client.admin_initiate_auth(
            UserPoolId=pool_id,
            ClientId=client_id,
            AuthFlow="ADMIN_USER_PASSWORD_AUTH",
            AuthParameters={
                "USERNAME": admin_user,
                "PASSWORD": password,
            },
        )

        assert "AuthenticationResult" in response
        result = response["AuthenticationResult"]
        assert "AccessToken" in result
        assert "IdToken" in result
        assert "RefreshToken" in result

    def test_access_token_format(self, deployed_env):
        """Test that access token has JWT format."""
        access_token = deployed_env.get("ACCESS_TOKEN")
        if not access_token:
            pytest.skip("No access token available")

        # JWT has 3 parts separated by dots
        parts = access_token.split(".")
        assert len(parts) == 3, "JWT should have 3 parts"

    def test_id_token_format(self, deployed_env):
        """Test that ID token has JWT format."""
        id_token = deployed_env.get("ID_TOKEN")
        if not id_token:
            pytest.skip("No ID token available")

        # JWT has 3 parts separated by dots
        parts = id_token.split(".")
        assert len(parts) == 3, "JWT should have 3 parts"

    def test_create_additional_user(self, deployed_env):
        """Test creating an additional user via admin API."""
        pool_id = deployed_env.get("POOL_ID")

        client = cognito_client()

        # Create new user
        response = client.admin_create_user(
            UserPoolId=pool_id,
            Username="test_user_2",
            MessageAction="SUPPRESS",
        )
        assert response["User"]["Username"] == "test_user_2"

        # Clean up
        client.admin_delete_user(
            UserPoolId=pool_id,
            Username="test_user_2",
        )

    def test_user_password_auth_flow(self, deployed_env):
        """Test USER_PASSWORD_AUTH flow."""
        pool_id = deployed_env.get("POOL_ID")
        client_id = deployed_env.get("CLIENT_ID")
        admin_user = deployed_env.get("ADMIN_USER")
        password = deployed_env.get("TEST_PASSWORD")

        client = cognito_client()
        response = client.initiate_auth(
            ClientId=client_id,
            AuthFlow="USER_PASSWORD_AUTH",
            AuthParameters={
                "USERNAME": admin_user,
                "PASSWORD": password,
            },
        )

        assert "AuthenticationResult" in response

    def test_refresh_token_flow(self, deployed_env):
        """Test refreshing tokens with refresh token."""
        pool_id = deployed_env.get("POOL_ID")
        client_id = deployed_env.get("CLIENT_ID")
        refresh_token = deployed_env.get("REFRESH_TOKEN")

        if not refresh_token:
            pytest.skip("No refresh token available")

        client = cognito_client()
        response = client.initiate_auth(
            ClientId=client_id,
            AuthFlow="REFRESH_TOKEN_AUTH",
            AuthParameters={
                "REFRESH_TOKEN": refresh_token,
            },
        )

        assert "AuthenticationResult" in response
        assert "AccessToken" in response["AuthenticationResult"]
