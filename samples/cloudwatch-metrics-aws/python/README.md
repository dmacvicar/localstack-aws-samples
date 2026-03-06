# CloudWatch Metrics and Alarms

This sample demonstrates CloudWatch metric alarms triggered by Lambda errors, with SNS email notifications.

## Overview

The sample creates:
1. A Lambda function that intentionally fails
2. A CloudWatch alarm monitoring Lambda errors
3. An SNS topic for alarm notifications
4. Email subscription to the SNS topic

When the Lambda fails, CloudWatch detects the error metric and triggers the alarm, which sends an email notification via SNS.

## Architecture

```
Lambda (fails on invoke)
    └── CloudWatch Metrics (Errors)
         └── CloudWatch Alarm (threshold: 1 error)
              └── SNS Topic
                   └── Email Notification (requires SMTP)
```

## Prerequisites

- LocalStack Pro
- Python 3.10+
- (Optional) SMTP server for email notifications

## SMTP Configuration (Optional)

To receive email notifications, configure SMTP when starting LocalStack:

```bash
LOCALSTACK_AUTH_TOKEN=... \
SMTP_HOST=host.docker.internal:2525 \
localstack start
```

You can use a mock SMTP server like [smtp4dev](https://github.com/rnwood/smtp4dev):

```bash
docker run --rm -p 3000:80 -p 2525:25 rnwood/smtp4dev
```

Then access the UI at http://localhost:3000 to view received emails.

## IaC Methods

| Method | Status | Notes |
|--------|--------|-------|
| scripts | Supported | AWS CLI deployment |
| terraform | Not implemented | |
| cloudformation | Not implemented | |
| cdk | Not implemented | |

## Deployment

```bash
cd samples/cloudwatch-metrics-aws/python

# Deploy
./scripts/deploy.sh

# Teardown
./scripts/teardown.sh
```

## Testing

```bash
# Run all tests
uv run pytest samples/cloudwatch-metrics-aws/python/ -v
```

Most tests work without SMTP. The core CloudWatch alarm functionality is tested regardless of SMTP configuration.

## How It Works

1. **Lambda Creation**: A Lambda that raises an exception on every invocation

2. **Alarm Setup**: CloudWatch alarm watches the `AWS/Lambda` namespace for `Errors` metric

3. **Invocation**: When Lambda is invoked and fails, error metrics are published

4. **Alarm Trigger**: When errors >= 1 within the evaluation period, alarm triggers

5. **Notification**: SNS sends email to subscribers (requires SMTP)

## Resources Created

- Lambda Function: `cw-failing-lambda`
- SNS Topic: `cw-alarm-topic`
- CloudWatch Alarm: `cw-lambda-alarm`

## Environment Variables

After deployment, the following variables are written to `scripts/.env`:

- `FUNCTION_NAME`: Lambda function name
- `LAMBDA_ARN`: Lambda ARN
- `TOPIC_NAME`: SNS topic name
- `TOPIC_ARN`: SNS topic ARN
- `ALARM_NAME`: CloudWatch alarm name
- `ALARM_STATE`: Current alarm state
- `TEST_EMAIL`: Email address for notifications
- `SMTP_CONFIGURED`: Whether SMTP was detected

## Triggering the Alarm

After deployment, invoke the Lambda to trigger the alarm:

```bash
awslocal lambda invoke --function-name cw-failing-lambda /dev/null
```

Check alarm state:

```bash
awslocal cloudwatch describe-alarms --alarm-names cw-lambda-alarm \
    --query 'MetricAlarms[0].StateValue'
```

## License

Apache 2.0
