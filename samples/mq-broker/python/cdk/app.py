#!/usr/bin/env python3
import os
import time
from aws_cdk import (
    App,
    Stack,
    CfnOutput,
    aws_amazonmq as mq,
)
from constructs import Construct


class MQBrokerStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        suffix = str(int(time.time()))
        broker_name = f"mq-broker-{suffix}"
        username = "admin"
        password = "Admin123456!"

        # MQ Broker
        broker = mq.CfnBroker(
            self,
            "MQBroker",
            broker_name=broker_name,
            deployment_mode="SINGLE_INSTANCE",
            engine_type="ACTIVEMQ",
            engine_version="5.18",
            host_instance_type="mq.m5.large",
            publicly_accessible=True,
            auto_minor_version_upgrade=True,
            users=[
                mq.CfnBroker.UserProperty(
                    username=username,
                    password=password,
                    console_access=True,
                    groups=["admin"],
                )
            ],
        )

        # Outputs
        CfnOutput(self, "BrokerId", value=broker.ref)
        CfnOutput(self, "BrokerName", value=broker_name)
        CfnOutput(self, "BrokerArn", value=broker.attr_arn)
        CfnOutput(self, "Username", value=username)
        CfnOutput(self, "Password", value=password)


app = App()
MQBrokerStack(
    app,
    "MQBrokerStack",
    env={
        "account": os.environ.get("CDK_DEFAULT_ACCOUNT", "000000000000"),
        "region": os.environ.get("CDK_DEFAULT_REGION", "us-east-1"),
    },
)
app.synth()
