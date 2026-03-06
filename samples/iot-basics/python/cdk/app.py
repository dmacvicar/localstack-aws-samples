#!/usr/bin/env python3
import os
import time
from aws_cdk import (
    App,
    Stack,
    CfnOutput,
    aws_iot as iot,
)
from constructs import Construct


class IoTBasicsStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        suffix = str(int(time.time()))

        # IoT Thing
        thing = iot.CfnThing(
            self,
            "IoTThing",
            thing_name=f"iot-thing-{suffix}",
            attribute_payload=iot.CfnThing.AttributePayloadProperty(
                attributes={
                    "env": "test",
                    "version": "1.0",
                }
            ),
        )

        # IoT Policy
        policy = iot.CfnPolicy(
            self,
            "IoTPolicy",
            policy_name=f"iot-policy-{suffix}",
            policy_document={
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Action": [
                            "iot:Connect",
                            "iot:Publish",
                            "iot:Subscribe",
                            "iot:Receive",
                        ],
                        "Resource": "*",
                    }
                ],
            },
        )

        # IoT Topic Rule
        rule = iot.CfnTopicRule(
            self,
            "IoTTopicRule",
            rule_name=f"rule_{suffix}",
            topic_rule_payload=iot.CfnTopicRule.TopicRulePayloadProperty(
                sql="SELECT * FROM 'iot/sensor/+'",
                actions=[],
                rule_disabled=False,
            ),
        )

        # Outputs
        CfnOutput(self, "ThingName", value=thing.thing_name)
        CfnOutput(self, "ThingArn", value=thing.attr_arn)
        CfnOutput(self, "PolicyName", value=policy.policy_name)
        CfnOutput(self, "PolicyArn", value=policy.attr_arn)
        CfnOutput(self, "RuleName", value=rule.rule_name)


app = App()
IoTBasicsStack(
    app,
    "IoTBasicsStack",
    env={
        "account": os.environ.get("CDK_DEFAULT_ACCOUNT", "000000000000"),
        "region": os.environ.get("CDK_DEFAULT_REGION", "us-east-1"),
    },
)
app.synth()
