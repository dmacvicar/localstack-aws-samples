# API Gateway Custom Domain

This sample demonstrates configuring a custom domain name for API Gateway HTTP API using ACM and Route53.

## Overview

The sample:
1. Generates a self-signed SSL certificate
2. Imports the certificate to ACM
3. Creates a Route53 hosted zone
4. Deploys a Lambda function with HTTP API
5. Configures a custom domain with API mapping
6. Creates DNS records in Route53

## Prerequisites

- LocalStack Pro (with valid `LOCALSTACK_AUTH_TOKEN`)
- OpenSSL (for certificate generation)
- AWS CLI or `awslocal`

## Usage

Start LocalStack:
```bash
localstack start
```

Deploy the sample:
```bash
./scripts/deploy.sh
```

Run tests:
```bash
./scripts/test.sh
```

Test manually:
```bash
curl -H 'Host: api.example.com' http://localhost.localstack.cloud:4566/hello
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      Route53                            │
│              api.example.com → CNAME                    │
└─────────────────────┬───────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────┐
│              API Gateway HTTP API                       │
│                Custom Domain                            │
│           (api.example.com + ACM cert)                  │
└─────────────────────┬───────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────┐
│                    Lambda                               │
│              /hello  →  hello()                         │
│              /goodbye → goodbye()                       │
└─────────────────────────────────────────────────────────┘
```

## AWS Services Used

- **API Gateway v2** - HTTP API with custom domain
- **ACM** - SSL/TLS certificate management
- **Route53** - DNS hosting and routing
- **Lambda** - Serverless function handlers
- **IAM** - Execution roles

## Files

```
apigw-custom-domain/python/
├── handler.py              # Lambda handlers
├── README.md
├── .gitignore
└── scripts/
    ├── deploy.sh          # Deployment script
    └── test.sh            # Test script
```

## Custom Domain Testing

LocalStack routes requests based on the `Host` header:

```bash
# Via custom domain (using Host header)
curl -H 'Host: api.example.com' http://localhost.localstack.cloud:4566/hello

# Direct API endpoint
curl http://{api-id}.execute-api.localhost.localstack.cloud:4566/hello
```
