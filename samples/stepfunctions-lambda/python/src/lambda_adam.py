"""
Lambda function for Step Functions sample - Adam branch.

Extracts the 'adam' field from the input event.
"""


def handler(event, context):
    """
    Extract the 'adam' field from the input.

    Args:
        event: Input containing {"input": {"adam": "value"}}
        context: Lambda context

    Returns:
        The value of the 'adam' field
    """
    return event["input"]["adam"]
