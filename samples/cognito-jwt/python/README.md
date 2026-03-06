# Cognito JWT Authentication

This sample demonstrates Amazon Cognito User Pools and JWT token authentication with LocalStack.

## Overview

The sample creates:
1. A Cognito User Pool with password policy
2. A User Pool Client for authentication
3. An admin user with a pre-set password
4. JWT tokens (Access, ID, Refresh) via authentication

## Architecture

```
Cognito User Pool
    └── User Pool Client
         └── Admin User (password set via admin API)
              └── JWT Tokens (Access, ID, Refresh)
```

## Prerequisites

- LocalStack Pro
- Python 3.10+
- (Optional) SMTP server for email verification flows

## SMTP Configuration (Optional)

Email verification flows require SMTP. Configure when starting LocalStack:

```bash
LOCALSTACK_AUTH_TOKEN=... \
SMTP_HOST=smtp.example.com:587 \
SMTP_USER=user \
SMTP_PASS=password \
localstack start
```

**Note**: The core functionality (user pools, authentication, JWT tokens) works without SMTP. Only email verification flows require it.

## IaC Methods

| Method | Status | Notes |
|--------|--------|-------|
| scripts | Supported | AWS CLI deployment |
| terraform | Not implemented | |
| cloudformation | Not implemented | |
| cdk | Not implemented | |

## Deployment

```bash
cd samples/cognito-jwt/python

# Deploy
./scripts/deploy.sh

# Teardown
./scripts/teardown.sh
```

## Testing

```bash
# Run all tests
uv run pytest samples/cognito-jwt/python/ -v
```

All tests work without SMTP by using admin APIs that bypass email verification.

## How It Works

1. **User Pool Creation**: Creates a pool with password policy

2. **Client Creation**: Creates a client with explicit auth flows enabled

3. **Admin User**: Uses `admin-create-user` with `MESSAGE_ACTION=SUPPRESS` to skip email

4. **Password Set**: Uses `admin-set-user-password --permanent` to confirm user

5. **Authentication**: Uses `admin-initiate-auth` with `ADMIN_USER_PASSWORD_AUTH` flow

6. **JWT Tokens**: Returns Access, ID, and Refresh tokens

## Resources Created

- User Pool: `test-user-pool`
- User Pool Client: `test-client`
- Admin User: `admin_user`

## Environment Variables

After deployment, the following variables are written to `scripts/.env`:

- `POOL_ID`: Cognito User Pool ID
- `POOL_ARN`: User Pool ARN
- `CLIENT_ID`: User Pool Client ID
- `ADMIN_USER`: Admin username
- `TEST_PASSWORD`: Admin password
- `ACCESS_TOKEN`: JWT access token
- `ID_TOKEN`: JWT ID token
- `REFRESH_TOKEN`: Refresh token
- `SMTP_CONFIGURED`: Whether SMTP was detected

## Authentication Example

After deployment, authenticate programmatically:

```bash
# Admin auth flow
awslocal cognito-idp admin-initiate-auth \
    --user-pool-id "$POOL_ID" \
    --client-id "$CLIENT_ID" \
    --auth-flow ADMIN_USER_PASSWORD_AUTH \
    --auth-parameters "USERNAME=admin_user,PASSWORD=TestPassword123!"

# User password auth flow
awslocal cognito-idp initiate-auth \
    --client-id "$CLIENT_ID" \
    --auth-flow USER_PASSWORD_AUTH \
    --auth-parameters "USERNAME=admin_user,PASSWORD=TestPassword123!"
```

## JWT Token Structure

The tokens returned are standard JWTs with three parts:
- Header (algorithm, type)
- Payload (claims: sub, iss, exp, etc.)
- Signature

Decode with any JWT library or online tool.

## License

Apache 2.0
