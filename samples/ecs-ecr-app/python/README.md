# ECS ECR Container App

This sample demonstrates deploying a containerized application to Amazon ECS using ECR for image storage, all running on LocalStack.

## Overview

The sample:
1. Creates an ECR repository
2. Builds and pushes a Docker image (nginx)
3. Deploys VPC infrastructure via CloudFormation
4. Creates an ECS Fargate service
5. Runs the container with networking

## Prerequisites

- LocalStack Pro (with valid `LOCALSTACK_AUTH_TOKEN`)
- Docker
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

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                         VPC                             │
│  ┌───────────────────────────────────────────────────┐  │
│  │                  Public Subnet                     │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │              ECS Cluster                     │  │  │
│  │  │  ┌───────────────────────────────────────┐  │  │  │
│  │  │  │         Fargate Task                   │  │  │  │
│  │  │  │  ┌─────────────────────────────────┐  │  │  │  │
│  │  │  │  │      nginx container            │  │  │  │  │
│  │  │  │  │      (from ECR)                 │  │  │  │  │
│  │  │  │  └─────────────────────────────────┘  │  │  │  │
│  │  │  └───────────────────────────────────────┘  │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                            │
                     ┌──────┴──────┐
                     │    ECR      │
                     │  Registry   │
                     └─────────────┘
```

## AWS Services Used

- **ECR** - Elastic Container Registry for Docker image storage
- **ECS** - Elastic Container Service for container orchestration
- **CloudFormation** - Infrastructure as Code
- **VPC** - Virtual Private Cloud networking
- **IAM** - Identity and Access Management

## Files

```
ecs-ecr-app/python/
├── Dockerfile              # nginx container image
├── index.html              # Custom welcome page
├── README.md
├── scripts/
│   ├── deploy.sh          # Deployment script
│   └── test.sh            # Test script
└── templates/
    ├── ecs-infra.yml      # VPC, cluster, IAM roles
    └── ecs-service.yml    # Task definition, service
```
