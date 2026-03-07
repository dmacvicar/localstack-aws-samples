# ELB Application Load Balancer

This sample demonstrates ELBv2 Application Load Balancers with Lambda targets using LocalStack.

## Overview

The sample creates:
1. A VPC with two subnets in different AZs
2. An Application Load Balancer (ALB)
3. Two Lambda functions as targets
4. Path-based routing rules (/hello1, /hello2)

## Architecture

```
Application Load Balancer
    └── HTTP Listener (port 80)
         ├── Rule: /hello1 → Target Group 1 → Lambda hello1
         └── Rule: /hello2 → Target Group 2 → Lambda hello2
```

## Prerequisites

- LocalStack Pro
- Node.js 18+ (for Lambda runtime)

## IaC Methods

| Method | Status | Notes |
|--------|--------|-------|
| scripts | Supported | AWS CLI deployment |
| terraform | Not implemented | |
| cloudformation | Not implemented | |
| cdk | Not implemented | |

## Deployment

```bash
cd samples/elb-load-balancing/javascript

# Deploy
./scripts/deploy.sh

# Teardown
./scripts/teardown.sh
```

## Testing

```bash
# Run all tests
uv run pytest samples/elb-load-balancing/javascript/ -v
```

## API Endpoints

After deployment, the ELB exposes:

| Endpoint | Lambda | Response |
|----------|--------|----------|
| `/hello1` | hello1 | `{"message": "Hello 1"}` |
| `/hello2` | hello2 | `{"message": "Hello 2"}` |

## Example Usage

```bash
# Load the environment
source scripts/.env

# Call hello1
curl $ELB_URL/hello1

# Call hello2
curl $ELB_URL/hello2
```

## Resources Created

- VPC with CIDR 10.0.0.0/16
- 2 Subnets (10.0.1.0/24, 10.0.2.0/24)
- Security Group (HTTP port 80)
- Application Load Balancer
- HTTP Listener on port 80
- 2 Target Groups (Lambda type)
- 2 Lambda Functions (hello1, hello2)
- Path-based routing rules

## Environment Variables

After deployment, the following variables are written to `scripts/.env`:

- `VPC_ID`: VPC identifier
- `SUBNET1_ID`, `SUBNET2_ID`: Subnet identifiers
- `SG_ID`: Security group ID
- `LB_NAME`: Load balancer name
- `LB_ARN`: Load balancer ARN
- `LB_DNS`: Load balancer DNS name
- `LISTENER_ARN`: HTTP listener ARN
- `TG1_ARN`, `TG2_ARN`: Target group ARNs
- `FUNC1_NAME`, `FUNC2_NAME`: Lambda function names
- `ELB_URL`: Full ELB URL for requests

## How ALB Lambda Integration Works

1. ALB receives HTTP request
2. Listener rules match the path pattern
3. Request forwarded to appropriate target group
4. Target group invokes Lambda with ALB event format
5. Lambda returns ALB-compatible response format

### ALB Lambda Response Format

```javascript
{
    isBase64Encoded: false,
    statusCode: 200,
    statusDescription: '200 OK',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ message: 'Hello' })
}
```

## License

Apache 2.0
