#!/bin/bash

# AWS Infrastructure Automation - Deployment Script
# This script deploys the serverless infrastructure to AWS

set -e  # Exit on any error

echo "🚀 Starting AWS Infrastructure Deployment..."
echo "=============================================="

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform is not installed. Please install it first.${NC}"
    exit 1
fi

# Get AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✓ AWS Account ID: ${ACCOUNT_ID}${NC}"

# Navigate to terraform directory
cd terraform

# Initialize Terraform
echo -e "\n${BLUE}📦 Initializing Terraform...${NC}"
terraform init

# Validate configuration
echo -e "\n${BLUE}✅ Validating Terraform configuration...${NC}"
terraform validate

# Format code
echo -e "\n${BLUE}🎨 Formatting Terraform code...${NC}"
terraform fmt -recursive

# Plan deployment
echo -e "\n${BLUE}📋 Planning deployment...${NC}"
terraform plan -out=tfplan

# Ask for confirmation
echo -e "\n${YELLOW}⚠️  Review the plan above. Do you want to proceed with deployment? (yes/no)${NC}"
read -r response

if [ "$response" != "yes" ]; then
    echo -e "${RED}❌ Deployment cancelled.${NC}"
    rm -f tfplan
    exit 0
fi

# Apply configuration
echo -e "\n${BLUE}🔧 Applying Terraform configuration...${NC}"
terraform apply tfplan

# Clean up plan file
rm -f tfplan

# Get outputs
echo -e "\n${GREEN}✅ Deployment completed successfully!${NC}"
echo -e "\n${BLUE}📊 Infrastructure Outputs:${NC}"
terraform output

# Get API Gateway URL
API_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "Not available")
CLOUDFRONT_DOMAIN=$(terraform output -raw cloudfront_domain 2>/dev/null || echo "Not available")
S3_WEBSITE=$(terraform output -raw s3_website_endpoint 2>/dev/null || echo "Not available")

echo -e "\n${GREEN}🌐 Your infrastructure is ready!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "📍 API Gateway URL: ${GREEN}${API_URL}${NC}"
echo -e "🌍 CloudFront Domain: ${GREEN}https://${CLOUDFRONT_DOMAIN}${NC}"
echo -e "🪣 S3 Website: ${GREEN}http://${S3_WEBSITE}${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Upload website files
echo -e "\n${BLUE}📤 Uploading website files to S3...${NC}"
cd ..
BUCKET_NAME="aws-infra-automation-website-${ACCOUNT_ID}"

aws s3 sync website/ s3://${BUCKET_NAME}/ --delete

echo -e "${GREEN}✓ Website files uploaded${NC}"

# Invalidate CloudFront cache
echo -e "\n${BLUE}🔄 Creating CloudFront invalidation...${NC}"
DISTRIBUTION_ID=$(aws cloudfront list-distributions --query "DistributionList.Items[?Comment=='aws-infra-automation CDN'].Id" --output text)

if [ -n "$DISTRIBUTION_ID" ]; then
    aws cloudfront create-invalidation --distribution-id ${DISTRIBUTION_ID} --paths "/*"
    echo -e "${GREEN}✓ CloudFront cache invalidated${NC}"
fi

echo -e "\n${GREEN}✅ Deployment complete!${NC}"
echo -e "\n${YELLOW}⚠️  IMPORTANT:${NC}"
echo -e "1. Update website/index.html with your API Gateway URL"
echo -e "2. Confirm your email subscription for CloudWatch alerts"
echo -e "3. Test your API at: ${GREEN}${API_URL}${NC}"
echo -e "4. Access your website at: ${GREEN}https://${CLOUDFRONT_DOMAIN}${NC}"
