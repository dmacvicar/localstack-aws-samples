#!/bin/bash
set -euo pipefail

# ELB Load Balancing Terraform deployment script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$SAMPLE_DIR/scripts/.env"

echo "Deploying ELB load balancing with Terraform..."

cd "$SCRIPT_DIR"

# Initialize Terraform
tflocal init -input=false

# Apply configuration
tflocal apply -auto-approve -input=false

# Extract outputs
VPC_ID=$(tflocal output -raw vpc_id)
SUBNET1_ID=$(tflocal output -raw subnet1_id)
SUBNET2_ID=$(tflocal output -raw subnet2_id)
SG_ID=$(tflocal output -raw sg_id)
LB_NAME=$(tflocal output -raw lb_name)
LB_ARN=$(tflocal output -raw lb_arn)
LB_DNS=$(tflocal output -raw lb_dns)
LISTENER_ARN=$(tflocal output -raw listener_arn)
TG1_ARN=$(tflocal output -raw tg1_arn)
TG2_ARN=$(tflocal output -raw tg2_arn)
FUNC1_NAME=$(tflocal output -raw func1_name)
FUNC1_ARN=$(tflocal output -raw func1_arn)
FUNC2_NAME=$(tflocal output -raw func2_name)
FUNC2_ARN=$(tflocal output -raw func2_arn)
ELB_URL=$(tflocal output -raw elb_url)

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
