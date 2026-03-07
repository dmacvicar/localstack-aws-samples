#!/bin/bash
set -euo pipefail

# ELB Load Balancing deployment script
# Creates VPC, Subnet, ALB, Lambda functions, and target groups

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration
LB_NAME="${LB_NAME:-elb-test}"
FUNCTION_PREFIX="${FUNCTION_PREFIX:-elb-handler}"
AWS_REGION="${AWS_DEFAULT_REGION:-us-east-1}"

echo "Setting up ELB load balancing resources..."

# Create VPC
echo "Creating VPC..."
VPC_ID=$(awslocal ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --query 'Vpc.VpcId' \
    --output text)
echo "Created VPC: $VPC_ID"

# Enable DNS hostnames
awslocal ec2 modify-vpc-attribute \
    --vpc-id "$VPC_ID" \
    --enable-dns-hostnames '{"Value": true}'

# Create subnets in different AZs
echo "Creating subnets..."
SUBNET1_ID=$(awslocal ec2 create-subnet \
    --vpc-id "$VPC_ID" \
    --cidr-block 10.0.1.0/24 \
    --availability-zone "${AWS_REGION}a" \
    --query 'Subnet.SubnetId' \
    --output text)
echo "Created Subnet 1: $SUBNET1_ID"

SUBNET2_ID=$(awslocal ec2 create-subnet \
    --vpc-id "$VPC_ID" \
    --cidr-block 10.0.2.0/24 \
    --availability-zone "${AWS_REGION}b" \
    --query 'Subnet.SubnetId' \
    --output text)
echo "Created Subnet 2: $SUBNET2_ID"

# Create security group
echo "Creating security group..."
SG_ID=$(awslocal ec2 create-security-group \
    --group-name elb-sg \
    --description "Security group for ELB" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' \
    --output text)

awslocal ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 >/dev/null

echo "Created Security Group: $SG_ID"

# Create Lambda deployment package
echo "Creating Lambda functions..."
cd "$SAMPLE_DIR"
zip -j /tmp/handler.zip handler.js >/dev/null

# Create Lambda function 1
FUNC1_NAME="${FUNCTION_PREFIX}-hello1"
awslocal lambda create-function \
    --function-name "$FUNC1_NAME" \
    --runtime nodejs18.x \
    --handler handler.hello1 \
    --zip-file fileb:///tmp/handler.zip \
    --role arn:aws:iam::000000000000:role/lambda-role \
    --timeout 30 \
    --output json >/dev/null

FUNC1_ARN=$(awslocal lambda get-function \
    --function-name "$FUNC1_NAME" \
    --query 'Configuration.FunctionArn' \
    --output text)
echo "Created Lambda: $FUNC1_NAME"

# Create Lambda function 2
FUNC2_NAME="${FUNCTION_PREFIX}-hello2"
awslocal lambda create-function \
    --function-name "$FUNC2_NAME" \
    --runtime nodejs18.x \
    --handler handler.hello2 \
    --zip-file fileb:///tmp/handler.zip \
    --role arn:aws:iam::000000000000:role/lambda-role \
    --timeout 30 \
    --output json >/dev/null

FUNC2_ARN=$(awslocal lambda get-function \
    --function-name "$FUNC2_NAME" \
    --query 'Configuration.FunctionArn' \
    --output text)
echo "Created Lambda: $FUNC2_NAME"

# Wait for Lambdas to be active
echo "Waiting for Lambdas to be active..."
for func in "$FUNC1_NAME" "$FUNC2_NAME"; do
    for i in {1..30}; do
        STATE=$(awslocal lambda get-function --function-name "$func" \
            --query 'Configuration.State' --output text 2>/dev/null || echo "Pending")
        if [ "$STATE" = "Active" ]; then
            break
        fi
        sleep 1
    done
done

# Create Application Load Balancer
echo "Creating Application Load Balancer..."
LB_ARN=$(awslocal elbv2 create-load-balancer \
    --name "$LB_NAME" \
    --subnets "$SUBNET1_ID" "$SUBNET2_ID" \
    --security-groups "$SG_ID" \
    --scheme internet-facing \
    --type application \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text)

LB_DNS=$(awslocal elbv2 describe-load-balancers \
    --load-balancer-arns "$LB_ARN" \
    --query 'LoadBalancers[0].DNSName' \
    --output text)
echo "Created ALB: $LB_NAME (DNS: $LB_DNS)"

# Create target groups for Lambda
echo "Creating target groups..."
TG1_ARN=$(awslocal elbv2 create-target-group \
    --name tg-hello1 \
    --target-type lambda \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)

TG2_ARN=$(awslocal elbv2 create-target-group \
    --name tg-hello2 \
    --target-type lambda \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)

echo "Created Target Groups"

# Register Lambda functions as targets
echo "Registering Lambda targets..."
awslocal elbv2 register-targets \
    --target-group-arn "$TG1_ARN" \
    --targets "Id=$FUNC1_ARN"

awslocal elbv2 register-targets \
    --target-group-arn "$TG2_ARN" \
    --targets "Id=$FUNC2_ARN"

# Create listener with default action
echo "Creating listener..."
LISTENER_ARN=$(awslocal elbv2 create-listener \
    --load-balancer-arn "$LB_ARN" \
    --protocol HTTP \
    --port 80 \
    --default-actions "Type=fixed-response,FixedResponseConfig={StatusCode=404,ContentType=text/plain,MessageBody=Not Found}" \
    --query 'Listeners[0].ListenerArn' \
    --output text)

# Create rules for path-based routing
echo "Creating listener rules..."
awslocal elbv2 create-rule \
    --listener-arn "$LISTENER_ARN" \
    --priority 1 \
    --conditions "Field=path-pattern,Values=/hello1" \
    --actions "Type=forward,TargetGroupArn=$TG1_ARN" >/dev/null

awslocal elbv2 create-rule \
    --listener-arn "$LISTENER_ARN" \
    --priority 2 \
    --conditions "Field=path-pattern,Values=/hello2" \
    --actions "Type=forward,TargetGroupArn=$TG2_ARN" >/dev/null

# Construct the ELB URL
ELB_URL="http://${LB_DNS}:4566"

echo ""
echo "ELB resources created successfully!"
echo "  Load Balancer: $LB_NAME"
echo "  DNS Name: $LB_DNS"
echo "  ELB URL: $ELB_URL"
echo "  Endpoints:"
echo "    - $ELB_URL/hello1"
echo "    - $ELB_URL/hello2"

# Write environment variables
cat > "$SCRIPT_DIR/.env" << EOF
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
echo "Environment written to $SCRIPT_DIR/.env"
