#!/bin/bash
set -euo pipefail

# ELB Load Balancing CDK deployment script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$SAMPLE_DIR/scripts/.env"
STACK_NAME="ElbLoadBalancingStack"

echo "Deploying ELB load balancing with CDK..."

cd "$SCRIPT_DIR"

# Install CDK dependencies
pip install -q -r requirements.txt

# Bootstrap CDK (if needed)
cdklocal bootstrap --quiet 2>/dev/null || true

# Deploy
cdklocal deploy "$STACK_NAME" --require-approval never --outputs-file outputs.json

# Extract outputs
VPC_ID=$(jq -r ".[\"$STACK_NAME\"].VpcId" outputs.json)
SUBNET1_ID=$(jq -r ".[\"$STACK_NAME\"].Subnet1Id" outputs.json)
SUBNET2_ID=$(jq -r ".[\"$STACK_NAME\"].Subnet2Id" outputs.json)
SG_ID=$(jq -r ".[\"$STACK_NAME\"].SgId" outputs.json)
LB_NAME=$(jq -r ".[\"$STACK_NAME\"].LBName" outputs.json)
LB_ARN=$(jq -r ".[\"$STACK_NAME\"].LBArn" outputs.json)
LB_DNS=$(jq -r ".[\"$STACK_NAME\"].LBDNS" outputs.json)
LISTENER_ARN=$(jq -r ".[\"$STACK_NAME\"].ListenerArn" outputs.json)
TG1_ARN=$(jq -r ".[\"$STACK_NAME\"].TG1Arn" outputs.json)
TG2_ARN=$(jq -r ".[\"$STACK_NAME\"].TG2Arn" outputs.json)
FUNC1_NAME=$(jq -r ".[\"$STACK_NAME\"].Func1Name" outputs.json)
FUNC1_ARN=$(jq -r ".[\"$STACK_NAME\"].Func1Arn" outputs.json)
FUNC2_NAME=$(jq -r ".[\"$STACK_NAME\"].Func2Name" outputs.json)
FUNC2_ARN=$(jq -r ".[\"$STACK_NAME\"].Func2Arn" outputs.json)
ELB_URL=$(jq -r ".[\"$STACK_NAME\"].ELBURL" outputs.json)

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
