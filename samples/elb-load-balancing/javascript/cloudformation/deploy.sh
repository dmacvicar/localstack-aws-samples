#!/bin/bash
set -euo pipefail

# ELB Load Balancing CloudFormation deployment script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$SAMPLE_DIR/scripts/.env"
STACK_NAME="elb-load-balancing"

echo "Deploying ELB load balancing with CloudFormation..."

cd "$SCRIPT_DIR"

# Deploy stack
awslocal cloudformation deploy \
    --template-file template.yml \
    --stack-name "$STACK_NAME" \
    --capabilities CAPABILITY_NAMED_IAM \
    --no-fail-on-empty-changeset

# Wait for stack to complete
echo "Waiting for stack to complete..."
awslocal cloudformation wait stack-create-complete --stack-name "$STACK_NAME" 2>/dev/null || \
awslocal cloudformation wait stack-update-complete --stack-name "$STACK_NAME" 2>/dev/null || true

# Get outputs
get_output() {
    awslocal cloudformation describe-stacks --stack-name "$STACK_NAME" \
        --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue" --output text
}

VPC_ID=$(get_output "VpcId")
SUBNET1_ID=$(get_output "Subnet1Id")
SUBNET2_ID=$(get_output "Subnet2Id")
SG_ID=$(get_output "SecurityGroupId")
LB_NAME=$(get_output "LBName")
LB_ARN=$(get_output "LBArn")
LB_DNS=$(get_output "LBDNS")
LISTENER_ARN=$(get_output "ListenerArn")
TG1_ARN=$(get_output "TG1Arn")
TG2_ARN=$(get_output "TG2Arn")
FUNC1_NAME=$(get_output "Func1Name")
FUNC1_ARN=$(get_output "Func1Arn")
FUNC2_NAME=$(get_output "Func2Name")
FUNC2_ARN=$(get_output "Func2Arn")
ELB_URL=$(get_output "ELBURL")

echo ""
echo "ELB resources created successfully!"
echo "  Load Balancer: $LB_NAME"
echo "  DNS Name: $LB_DNS"
echo "  ELB URL: $ELB_URL"
echo "  Endpoints:"
echo "    - $ELB_URL/hello1"
echo "    - $ELB_URL/hello2"

# Write environment variables
mkdir -p "$(dirname "$ENV_FILE")"
cat > "$ENV_FILE" << EOF
VPC_ID=$VPC_ID
SUBNET1_ID=$SUBNET1_ID
SUBNET2_ID=$SUBNET2_ID
SG_ID=$SG_ID
LB_NAME=$LB_NAME
LB_ARN=$LB_ARN
LB_DNS=$LB_DNS
LISTENER_ARN=$LISTENER_ARN
TG1_ARN=$TG1_ARN
TG2_ARN=$TG2_ARN
FUNC1_NAME=$FUNC1_NAME
FUNC1_ARN=$FUNC1_ARN
FUNC2_NAME=$FUNC2_NAME
FUNC2_ARN=$FUNC2_ARN
ELB_URL=$ELB_URL
EOF

echo ""
echo "Environment written to $ENV_FILE"
