#!/bin/bash
set -euo pipefail

# ELB Load Balancing teardown script
# Cleans up all ELB, Lambda, and VPC resources

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment if exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

echo "Tearing down ELB load balancing resources..."

# Delete listener rules and listener
if [ -n "${LISTENER_ARN:-}" ]; then
    echo "Deleting listener..."
    awslocal elbv2 delete-listener --listener-arn "$LISTENER_ARN" 2>/dev/null || true
fi

# Delete target groups
if [ -n "${TG1_ARN:-}" ]; then
    echo "Deleting target group 1..."
    awslocal elbv2 delete-target-group --target-group-arn "$TG1_ARN" 2>/dev/null || true
fi

if [ -n "${TG2_ARN:-}" ]; then
    echo "Deleting target group 2..."
    awslocal elbv2 delete-target-group --target-group-arn "$TG2_ARN" 2>/dev/null || true
fi

# Delete load balancer
if [ -n "${LB_ARN:-}" ]; then
    echo "Deleting load balancer..."
    awslocal elbv2 delete-load-balancer --load-balancer-arn "$LB_ARN" 2>/dev/null || true
    sleep 2  # Wait for LB to be deleted
fi

# Delete Lambda functions
if [ -n "${FUNC1_NAME:-}" ]; then
    echo "Deleting Lambda: $FUNC1_NAME"
    awslocal lambda delete-function --function-name "$FUNC1_NAME" 2>/dev/null || true
fi

if [ -n "${FUNC2_NAME:-}" ]; then
    echo "Deleting Lambda: $FUNC2_NAME"
    awslocal lambda delete-function --function-name "$FUNC2_NAME" 2>/dev/null || true
fi

# Delete security group
if [ -n "${SG_ID:-}" ]; then
    echo "Deleting security group..."
    awslocal ec2 delete-security-group --group-id "$SG_ID" 2>/dev/null || true
fi

# Delete subnets
if [ -n "${SUBNET1_ID:-}" ]; then
    echo "Deleting subnet 1..."
    awslocal ec2 delete-subnet --subnet-id "$SUBNET1_ID" 2>/dev/null || true
fi

if [ -n "${SUBNET2_ID:-}" ]; then
    echo "Deleting subnet 2..."
    awslocal ec2 delete-subnet --subnet-id "$SUBNET2_ID" 2>/dev/null || true
fi

# Delete VPC
if [ -n "${VPC_ID:-}" ]; then
    echo "Deleting VPC..."
    awslocal ec2 delete-vpc --vpc-id "$VPC_ID" 2>/dev/null || true
fi

# Clean up temp files
rm -f /tmp/handler.zip

# Clean up .env file
rm -f "$SCRIPT_DIR/.env"

echo "Teardown complete"
