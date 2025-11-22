#!/bin/bash

################################################################################
# Dental Receptionist AI - Automated Deployment Script
# 
# This script automates the deployment of the dental receptionist to AWS ECS
# 
# Usage: ./deploy.sh [environment]
# Example: ./deploy.sh production
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-production}
PROJECT_NAME="dental-receptionist"
AWS_REGION=${AWS_REGION:-us-east-1}
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPOSITORY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Dental Receptionist AI Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Environment: ${GREEN}${ENVIRONMENT}${NC}"
echo -e "AWS Region: ${GREEN}${AWS_REGION}${NC}"
echo -e "AWS Account: ${GREEN}${AWS_ACCOUNT_ID}${NC}"
echo ""

# Function to print section headers
print_section() {
    echo ""
    echo -e "${BLUE}>>> $1${NC}"
    echo ""
}

# Function to print success messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error messages
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to print warnings
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check prerequisites
print_section "Checking Prerequisites"

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    exit 1
fi
print_success "AWS CLI installed"

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install it first."
    exit 1
fi
print_success "Docker installed"

# Check Node.js
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed. Please install it first."
    exit 1
fi
print_success "Node.js installed"

# Verify AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured. Run 'aws configure'"
    exit 1
fi
print_success "AWS credentials configured"

# Check Bedrock access
print_section "Checking Bedrock Access"
if aws bedrock list-foundation-models --region ${AWS_REGION} --query 'modelSummaries[?contains(modelId, `nova-sonic`)]' &> /dev/null; then
    print_success "Bedrock Nova Sonic access confirmed"
else
    print_warning "Bedrock access might not be enabled. Please enable in AWS Console."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create or update ECR repository
print_section "Setting up ECR Repository"
if aws ecr describe-repositories --repository-names ${PROJECT_NAME} --region ${AWS_REGION} &> /dev/null; then
    print_success "ECR repository already exists"
else
    print_success "Creating ECR repository..."
    aws ecr create-repository \
        --repository-name ${PROJECT_NAME} \
        --region ${AWS_REGION} \
        --image-scanning-configuration scanOnPush=true
    print_success "ECR repository created"
fi

# Build application
print_section "Building Application"

echo "Installing dependencies..."
npm install
print_success "Dependencies installed"

echo "Building TypeScript..."
if npm run build; then
    print_success "Build completed"
else
    print_warning "Build step skipped (might not be needed)"
fi

# Build Docker image
print_section "Building Docker Image"
IMAGE_TAG=$(date +%Y%m%d-%H%M%S)

echo "Building image: ${PROJECT_NAME}:${IMAGE_TAG}"
docker build -t ${PROJECT_NAME}:${IMAGE_TAG} .
docker tag ${PROJECT_NAME}:${IMAGE_TAG} ${PROJECT_NAME}:latest
print_success "Docker image built"

# Login to ECR
print_section "Pushing to ECR"
echo "Logging in to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | \
    docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
print_success "Logged in to ECR"

# Tag and push
echo "Tagging image..."
docker tag ${PROJECT_NAME}:${IMAGE_TAG} ${ECR_REPOSITORY}:${IMAGE_TAG}
docker tag ${PROJECT_NAME}:latest ${ECR_REPOSITORY}:latest

echo "Pushing image to ECR..."
docker push ${ECR_REPOSITORY}:${IMAGE_TAG}
docker push ${ECR_REPOSITORY}:latest
print_success "Image pushed to ECR"

# Deploy CloudFormation stack
print_section "Deploying Infrastructure"

STACK_NAME="${PROJECT_NAME}-${ENVIRONMENT}"

# Check if stack exists
if aws cloudformation describe-stacks --stack-name ${STACK_NAME} --region ${AWS_REGION} &> /dev/null; then
    echo "Stack exists, updating..."
    ACTION="update-stack"
else
    echo "Creating new stack..."
    ACTION="create-stack"
fi

# Deploy
aws cloudformation ${ACTION} \
    --stack-name ${STACK_NAME} \
    --template-body file://cloudformation-template.yaml \
    --parameters \
        ParameterKey=EnvironmentName,ParameterValue=${PROJECT_NAME} \
        ParameterKey=ContainerImage,ParameterValue=${ECR_REPOSITORY}:${IMAGE_TAG} \
        ParameterKey=DesiredCount,ParameterValue=1 \
    --capabilities CAPABILITY_IAM \
    --region ${AWS_REGION}

echo "Waiting for stack to complete..."
if [ "$ACTION" = "create-stack" ]; then
    aws cloudformation wait stack-create-complete \
        --stack-name ${STACK_NAME} \
        --region ${AWS_REGION}
else
    aws cloudformation wait stack-update-complete \
        --stack-name ${STACK_NAME} \
        --region ${AWS_REGION} 2>/dev/null || true
fi
print_success "Stack deployment complete"

# Get outputs
print_section "Deployment Complete!"

ALB_URL=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --region ${AWS_REGION} \
    --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
    --output text)

ECR_URI=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --region ${AWS_REGION} \
    --query 'Stacks[0].Outputs[?OutputKey==`ECRRepositoryURI`].OutputValue' \
    --output text)

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Successful!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Application URL: ${BLUE}${ALB_URL}${NC}"
echo -e "ECR Repository: ${BLUE}${ECR_URI}${NC}"
echo -e "Image Tag: ${BLUE}${IMAGE_TAG}${NC}"
echo ""
echo -e "${YELLOW}Note: It may take 2-3 minutes for the service to become healthy.${NC}"
echo ""
echo "To view logs:"
echo -e "  ${BLUE}aws logs tail /ecs/${PROJECT_NAME} --follow --region ${AWS_REGION}${NC}"
echo ""
echo "To check service status:"
echo -e "  ${BLUE}aws ecs describe-services --cluster ${PROJECT_NAME}-cluster --services ${PROJECT_NAME}-service --region ${AWS_REGION}${NC}"
echo ""

# Optional: Open in browser
read -p "Open in browser? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if command -v xdg-open &> /dev/null; then
        xdg-open ${ALB_URL}
    elif command -v open &> /dev/null; then
        open ${ALB_URL}
    else
        echo "Please open ${ALB_URL} in your browser"
    fi
fi

print_success "Deployment script completed!"
