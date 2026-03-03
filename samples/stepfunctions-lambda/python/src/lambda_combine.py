"""
Lambda function for Step Functions sample - Combine results.

Combines the outputs from the parallel Adam and Cole branches.
"""


def handler(event, context):
    """
    Combine the results from parallel branches.

    Args:
        event: Input containing {"input": ["value1", "value2"]}
        context: Lambda context

    Returns:
        Combined message from both branches
    """
    values = event["input"]
    return "Together Adam and Cole say '{}'!!".format(' '.join(values))
