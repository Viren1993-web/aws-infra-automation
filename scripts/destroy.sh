#!/bin/bash

# AWS Infrastructure Automation - Destroy Script
# This script safely destroys all AWS resources

set -e  # Exit on any error

echo "🗑️  AWS Infrastructure Destruction Script"
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Warning message
echo -e "${RED}"
echo "⚠️  WARNING ⚠️"
echo "This will destroy ALL infrastructure resources including:"
echo "  - S3 buckets and all files"
echo "  - Lambda functions"
echo "  - API Gateway"
echo "  - DynamoDB table and all data"
echo "  - CloudFront distribution"
echo "  - VPC and networking"
echo "  - CloudWatch alarms and logs"
echo -e "${NC}"

# Ask for confirmation
echo -e "${YELLOW}Are you sure you want to proceed? Type 'destroy' to confirm:${NC}"
read -r response

if [ "$response" != "destroy" ]; then
    echo -e "${GREEN}❌ Destruction cancelled. Your infrastructure is safe.${NC}"
    exit 0
fi

# Get AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✓ AWS Account ID: ${ACCOUNT_ID}${NC}"

# Empty S3 buckets before destruction
echo -e "\n${YELLOW}🪣 Emptying S3 buckets...${NC}"
WEBSITE_BUCKET="aws-infra-automation-website-${ACCOUNT_ID}"
STATE_BUCKET="aws-infra-automation-tfstate-${ACCOUNT_ID}"

if aws s3 ls "s3://${WEBSITE_BUCKET}" 2>/dev/null; then
    echo "Emptying ${WEBSITE_BUCKET}..."
    aws s3 rm "s3://${WEBSITE_BUCKET}" --recursive
fi

if aws s3 ls "s3://${STATE_BUCKET}" 2>/dev/null; then
    echo "Emptying ${STATE_BUCKET}..."
    aws s3 rm "s3://${STATE_BUCKET}" --recursive
fi

# Navigate to terraform directory
cd terraform

# Destroy infrastructure
echo -e "\n${RED}💥 Destroying infrastructure...${NC}"
terraform destroy -auto-approve

echo -e "\n${GREEN}✅ Infrastructure destroyed successfully!${NC}"
echo -e "${GREEN}All AWS resources have been removed.${NC}"
