# API Gateway WebSockets Sample (JavaScript)

This sample demonstrates WebSocket APIs using API Gateway V2 and Lambda with LocalStack.

## What it Does

API Gateway WebSockets provide real-time, two-way communication between clients and backend services. Unlike REST APIs, WebSocket connections remain open, allowing the server to push data to clients.

This sample:
1. Creates a **WebSocket API** with API Gateway V2
2. Configures **route handlers** for connection lifecycle and messages
3. **Echoes messages** back to demonstrate bidirectional communication

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    WebSocket API Gateway                     │
│                                                              │
│   Routes:                                                    │
│   ├── $connect     → connectionHandler Lambda                │
│   ├── $disconnect  → connectionHandler Lambda                │
│   ├── $default     → defaultHandler Lambda                   │
│   └── test-action  → actionHandler Lambda                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                 ┌─────────────────────────┐
                 │    Lambda Functions     │
                 │                         │
                 │  Echo events back to    │
                 │  client for testing     │
                 └─────────────────────────┘
```

## Route Types

| Route | Description |
|-------|-------------|
| `$connect` | Called when a client connects |
| `$disconnect` | Called when a client disconnects |
| `$default` | Fallback for unmatched routes |
| `test-action` | Custom action route |

## Prerequisites

- LocalStack Pro running (`localstack start`)
- Node.js 18+
- npm
- Python 3 with `websockets` library (for tests)

## Quick Start

```bash
# Deploy
./scripts/deploy.sh

# Test
./scripts/test.sh
```

## Files

| File | Description |
|------|-------------|
| `handler.js` | Lambda handler for all WebSocket routes |
| `serverless.yml` | Serverless Framework configuration |
| `scripts/deploy.sh` | Deployment script |
| `scripts/test.sh` | Test script with validation |

## Manual Testing

Connect with wscat:
```bash
# Install wscat
npm install -g wscat

# Connect to WebSocket
wscat -c ws://localhost:4510

# Send a message
> {"action": "test-action", "data": "hello"}
```

## Tests

The test script validates:
1. WebSocket API exists
2. All Lambda functions are active
3. All routes are configured ($connect, $disconnect, $default, test-action)
4. WebSocket message round-trip works

## AWS Services Used

- API Gateway V2 (WebSocket)
- AWS Lambda
- S3 (deployment bucket)
