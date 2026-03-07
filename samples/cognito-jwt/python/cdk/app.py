#!/usr/bin/env python3
"""CDK app for Cognito JWT Authentication."""

import os

import aws_cdk as cdk
from aws_cdk import (
    Stack,
    aws_cognito as cognito,
    CfnOutput,
)
from constructs import Construct


class CognitoJwtStack(Stack):
    """Stack for Cognito User Pool and Client."""

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # Configuration
        pool_name = os.environ.get("POOL_NAME", "test-user-pool")
        client_name = os.environ.get("CLIENT_NAME", "test-client")

        # Cognito User Pool
        user_pool = cognito.UserPool(
            self,
            "UserPool",
            user_pool_name=pool_name,
            self_sign_up_enabled=True,
            sign_in_aliases=cognito.SignInAliases(
                username=True,
                email=True,
            ),
            auto_verify=cognito.AutoVerifiedAttrs(
                email=True,
            ),
            password_policy=cognito.PasswordPolicy(
                min_length=8,
                require_lowercase=True,
                require_uppercase=True,
                require_digits=True,
                require_symbols=False,
            ),
        )

        # Cognito User Pool Client
        user_pool_client = user_pool.add_client(
            "UserPoolClient",
            user_pool_client_name=client_name,
            auth_flows=cognito.AuthFlow(
                admin_user_password=True,
                user_password=True,
            ),
        )

        # Outputs
        CfnOutput(self, "PoolName", value=user_pool.user_pool_id)
        CfnOutput(self, "PoolId", value=user_pool.user_pool_id)
        CfnOutput(self, "PoolArn", value=user_pool.user_pool_arn)
        CfnOutput(self, "ClientName", value=client_name)
        CfnOutput(self, "ClientId", value=user_pool_client.user_pool_client_id)


app = cdk.App()
CognitoJwtStack(
    app,
    "CognitoJwtStack",
    env=cdk.Environment(
        account=os.environ.get("CDK_DEFAULT_ACCOUNT", "000000000000"),
        region=os.environ.get("CDK_DEFAULT_REGION", "us-east-1"),
    ),
)
app.synth()
