#!/usr/bin/env python3
import os
import time
from aws_cdk import (
    App,
    Stack,
    RemovalPolicy,
    CfnOutput,
    aws_s3 as s3,
    aws_s3_deployment as s3deploy,
    aws_glue as glue,
    aws_athena as athena,
)
from constructs import Construct


class AthenaS3QueriesStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        suffix = str(int(time.time()))

        # S3 bucket for data and results
        bucket = s3.Bucket(
            self,
            "AthenaBucket",
            bucket_name=f"athena-test-{suffix}",
            removal_policy=RemovalPolicy.DESTROY,
            auto_delete_objects=True,
        )

        # Upload test data
        s3deploy.BucketDeployment(
            self,
            "DeployData",
            sources=[s3deploy.Source.asset(os.path.join(os.path.dirname(__file__), "..", "data"))],
            destination_bucket=bucket,
            destination_key_prefix="data",
        )

        # Glue database
        database = glue.CfnDatabase(
            self,
            "GlueDatabase",
            catalog_id=self.account,
            database_input=glue.CfnDatabase.DatabaseInputProperty(
                name="test_db",
                location_uri=f"s3://{bucket.bucket_name}/test_db/",
            ),
        )

        # Glue table
        table = glue.CfnTable(
            self,
            "GlueTable",
            catalog_id=self.account,
            database_name="test_db",
            table_input=glue.CfnTable.TableInputProperty(
                name="test_table1",
                table_type="EXTERNAL_TABLE",
                parameters={
                    "skip.header.line.count": "1",
                    "EXTERNAL": "TRUE",
                },
                storage_descriptor=glue.CfnTable.StorageDescriptorProperty(
                    location=f"s3://{bucket.bucket_name}/data/",
                    input_format="org.apache.hadoop.mapred.TextInputFormat",
                    output_format="org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat",
                    serde_info=glue.CfnTable.SerdeInfoProperty(
                        serialization_library="org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe",
                        parameters={"field.delim": ","},
                    ),
                    columns=[
                        glue.CfnTable.ColumnProperty(name="id", type="int"),
                        glue.CfnTable.ColumnProperty(name="first_name", type="string"),
                        glue.CfnTable.ColumnProperty(name="last_name", type="string"),
                        glue.CfnTable.ColumnProperty(name="email", type="string"),
                        glue.CfnTable.ColumnProperty(name="gender", type="string"),
                        glue.CfnTable.ColumnProperty(name="is_active", type="boolean"),
                        glue.CfnTable.ColumnProperty(name="joined_date", type="string"),
                    ],
                ),
            ),
        )
        table.add_dependency(database)

        # Athena workgroup
        workgroup = athena.CfnWorkGroup(
            self,
            "AthenaWorkgroup",
            name=f"athena-workgroup-{suffix}",
            work_group_configuration=athena.CfnWorkGroup.WorkGroupConfigurationProperty(
                result_configuration=athena.CfnWorkGroup.ResultConfigurationProperty(
                    output_location=f"s3://{bucket.bucket_name}/results/",
                ),
            ),
        )

        # Outputs
        CfnOutput(self, "BucketName", value=bucket.bucket_name)
        CfnOutput(self, "DatabaseName", value="test_db")
        CfnOutput(self, "TableName", value="test_table1")
        CfnOutput(self, "WorkgroupName", value=workgroup.name)
        CfnOutput(self, "S3Output", value=f"s3://{bucket.bucket_name}/results")


app = App()
AthenaS3QueriesStack(
    app,
    "AthenaS3QueriesStack",
    env={
        "account": os.environ.get("CDK_DEFAULT_ACCOUNT", "000000000000"),
        "region": os.environ.get("CDK_DEFAULT_REGION", "us-east-1"),
    },
)
app.synth()
