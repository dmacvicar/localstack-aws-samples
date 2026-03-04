#!/usr/bin/env python3
"""Step Functions Lambda Sample - CDK Stack."""

import os
import aws_cdk as cdk
from aws_cdk import (
    Stack,
    aws_lambda as lambda_,
    aws_iam as iam,
    aws_stepfunctions as sfn,
    aws_stepfunctions_tasks as tasks,
    CfnOutput,
    Duration,
)
from constructs import Construct


class StepFunctionsLambdaStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # Lambda execution role
        lambda_role = iam.Role(
            self, "LambdaRole",
            role_name="cdk-sfn-lambda-role",
            assumed_by=iam.ServicePrincipal("lambda.amazonaws.com"),
        )

        # Adam Lambda function
        adam_code = '''
def handler(event, context):
    return event["input"]["adam"]
'''
        adam_fn = lambda_.Function(
            self, "AdamFunction",
            function_name="cdk-sfn-adam",
            runtime=lambda_.Runtime.PYTHON_3_12,
            handler="index.handler",
            code=lambda_.Code.from_inline(adam_code),
            timeout=Duration.seconds(30),
            memory_size=128,
            role=lambda_role,
        )

        # Cole Lambda function
        cole_code = '''
def handler(event, context):
    return event["input"]["cole"]
'''
        cole_fn = lambda_.Function(
            self, "ColeFunction",
            function_name="cdk-sfn-cole",
            runtime=lambda_.Runtime.PYTHON_3_12,
            handler="index.handler",
            code=lambda_.Code.from_inline(cole_code),
            timeout=Duration.seconds(30),
            memory_size=128,
            role=lambda_role,
        )

        # Combine Lambda function
        combine_code = '''
def handler(event, context):
    values = event["input"]
    return "Together Adam and Cole say '{}'!!".format(' '.join(values))
'''
        combine_fn = lambda_.Function(
            self, "CombineFunction",
            function_name="cdk-sfn-combine",
            runtime=lambda_.Runtime.PYTHON_3_12,
            handler="index.handler",
            code=lambda_.Code.from_inline(combine_code),
            timeout=Duration.seconds(30),
            memory_size=128,
            role=lambda_role,
        )

        # Step Functions tasks
        adam_task = tasks.LambdaInvoke(
            self, "AdamTask",
            lambda_function=adam_fn,
            output_path="$.Payload",
            payload=sfn.TaskInput.from_object({
                "input": sfn.JsonPath.entire_payload
            }),
        )

        cole_task = tasks.LambdaInvoke(
            self, "ColeTask",
            lambda_function=cole_fn,
            output_path="$.Payload",
            payload=sfn.TaskInput.from_object({
                "input": sfn.JsonPath.entire_payload
            }),
        )

        combine_task = tasks.LambdaInvoke(
            self, "CombineTask",
            lambda_function=combine_fn,
            output_path="$.Payload",
            payload=sfn.TaskInput.from_object({
                "input": sfn.JsonPath.entire_payload
            }),
        )

        # Parallel state
        parallel = sfn.Parallel(
            self, "ParallelState",
            comment="Execute Adam and Cole in parallel",
        )
        parallel.branch(adam_task)
        parallel.branch(cole_task)

        # Chain parallel -> combine
        definition = parallel.next(combine_task)

        # State machine
        state_machine = sfn.StateMachine(
            self, "StateMachine",
            state_machine_name="cdk-parallel-workflow",
            definition_body=sfn.DefinitionBody.from_chainable(definition),
            comment="A parallel state machine that demonstrates Step Functions orchestrating multiple Lambda functions",
        )

        # Outputs
        CfnOutput(self, "AdamFunctionOutput", value=adam_fn.function_name, export_name="AdamFunction")
        CfnOutput(self, "AdamArnOutput", value=adam_fn.function_arn, export_name="AdamArn")
        CfnOutput(self, "ColeFunctionOutput", value=cole_fn.function_name, export_name="ColeFunction")
        CfnOutput(self, "ColeArnOutput", value=cole_fn.function_arn, export_name="ColeArn")
        CfnOutput(self, "CombineFunctionOutput", value=combine_fn.function_name, export_name="CombineFunction")
        CfnOutput(self, "CombineArnOutput", value=combine_fn.function_arn, export_name="CombineArn")
        CfnOutput(self, "StateMachineNameOutput", value=state_machine.state_machine_name, export_name="StateMachineName")
        CfnOutput(self, "StateMachineArnOutput", value=state_machine.state_machine_arn, export_name="StateMachineArn")


app = cdk.App()
StepFunctionsLambdaStack(
    app, "StepFunctionsLambdaStack",
    env=cdk.Environment(
        account=os.environ.get("CDK_DEFAULT_ACCOUNT", "000000000000"),
        region=os.environ.get("CDK_DEFAULT_REGION", "us-east-1"),
    ),
)
app.synth()
