"""
Failing Lambda handler for CloudWatch metrics testing.

This Lambda intentionally raises an exception to trigger CloudWatch error metrics.
"""


def lambda_handler(event, context):
    """Handler that always fails to generate error metrics."""
    raise Exception("Intentional failure for CloudWatch metrics testing")
