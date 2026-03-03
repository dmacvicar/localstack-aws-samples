"""
Lambda function for Step Functions sample - Cole branch.

Extracts the 'cole' field from the input event.
"""


def handler(event, context):
    """
    Extract the 'cole' field from the input.

    Args:
        event: Input containing {"input": {"cole": "value"}}
        context: Lambda context

    Returns:
        The value of the 'cole' field
    """
    return event["input"]["cole"]
