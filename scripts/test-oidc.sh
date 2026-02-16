#!/bin/bash

# OIDC Setup Script for GitHub Actions + AWS
# This script automates OIDC provider and IAM role creation

set -e

echo "🔐 GitHub Actions OIDC Setup Script"
echo "===================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI not found. Please install it first.${NC}"
    exit 1
fi

# Get AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
if [ -z "$ACCOUNT_ID" ]; then
    echo -e "${RED}❌ Could not get AWS Account ID. Check your AWS credentials.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ AWS Account ID: ${ACCOUNT_ID}${NC}"

# Get GitHub repo
echo ""
echo -e "${BLUE}Enter your GitHub details:${NC}"
read -p "GitHub username: " GITHUB_USERNAME
read -p "Repository name (default: aws-infra-automation): " REPO_NAME
REPO_NAME=${REPO_NAME:-aws-infra-automation}

echo ""
echo -e "${YELLOW}Setting up OIDC for:${NC}"
echo "  Account ID: $ACCOUNT_ID"
echo "  Repository: $GITHUB_USERNAME/$REPO_NAME"
echo ""

# Step 1: Check if OIDC provider exists
echo -e "${BLUE}Step 1: Checking OIDC Provider...${NC}"

PROVIDER_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
PROVIDER_EXISTS=$(aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[*].Arn" --output text | grep -c "token.actions.githubusercontent.com" || true)

if [ "$PROVIDER_EXISTS" -eq 0 ]; then
    echo "Creating OIDC provider..."
    aws iam create-open-id-connect-provider \
        --url https://token.actions.githubusercontent.com \
        --client-id-list sts.amazonaws.com \
        --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
        > /dev/null
    echo -e "${GREEN}✓ OIDC provider created${NC}"
else
    echo -e "${GREEN}✓ OIDC provider already exists${NC}"
fi

# Step 2: Verify existing role
echo ""
echo -e "${BLUE}Step 2: Verifying Existing IAM Role...${NC}"

ROLE_NAME="DeployerAccess-Github"
ROLE_EXISTS=$(aws iam get-role --role-name "$ROLE_NAME" 2>/dev/null || echo "")

if [ -z "$ROLE_EXISTS" ]; then
    echo -e "${RED}❌ Role '$ROLE_NAME' not found!${NC}"
    echo "Please create the role first or check the role name."
    exit 1
else
    echo -e "${GREEN}✓ Role '$ROLE_NAME' found!${NC}"
fi

# Step 3: Check for inline or managed policies
echo ""
echo -e "${BLUE}Step 3: Verifying IAM Policies...${NC}"

# Check for inline policies
INLINE_POLICIES=$(aws iam list-role-policies --role-name "$ROLE_NAME" --query 'PolicyNames' --output text 2>/dev/null || echo "")

if [ -n "$INLINE_POLICIES" ]; then
    echo "Found inline policies attached to '$ROLE_NAME':"
    for policy in $INLINE_POLICIES; do
        echo "  ✓ $policy (inline policy)"
        
        # Show that DeployerAccessPolicy is expected
        if [ "$policy" = "DeployerAccessPolicy" ]; then
            echo "    └─ Your custom policy with S3, Lambda, DynamoDB, etc."
        fi
    done
else
    # Check for managed policies
    MANAGED_POLICIES=$(aws iam list-attached-role-policies --role-name "$ROLE_NAME" --query "AttachedPolicies[*].PolicyName" --output text 2>/dev/null || echo "")
    
    if [ -n "$MANAGED_POLICIES" ]; then
        echo "Found managed policies attached to '$ROLE_NAME':"
        for policy in $MANAGED_POLICIES; do
            echo "  ✓ $policy (managed policy)"
        done
    else
        echo -e "${YELLOW}⚠️  No policies found attached to '$ROLE_NAME'${NC}"
        echo "Please ensure the role has the necessary permissions for:"
        echo "  - S3, Lambda, DynamoDB, SNS, CloudFront"
        echo "  - EC2, CloudWatch, Logs, IAM, API Gateway"
    fi
fi

# Step 4: Get role ARN
echo ""
echo -e "${BLUE}Step 4: Verifying Setup...${NC}"

ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)
echo -e "${GREEN}✓ Role ARN: ${ROLE_ARN}${NC}"

# Step 5: Display next steps
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ OIDC Setup Verification Complete!${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo ""
echo "1️⃣  Verify your GitHub workflows use the correct Account ID:"
echo "   File: .github/workflows/terraform-ci.yml"
echo "   File: .github/workflows/terraform-cd.yml"
echo "   Check: AWS_ACCOUNT_ID: '${ACCOUNT_ID}'"
echo ""
echo "2️⃣  Ensure you have no old AWS secrets in GitHub:"
echo "   Go to: Settings → Secrets and variables → Actions"
echo "   Verify: AWS_ACCESS_KEY_ID (should not exist)"
echo "   Verify: AWS_SECRET_ACCESS_KEY (should not exist)"
echo ""
echo "3️⃣  Test your setup:"
echo "   git checkout -b test-oidc"
echo "   echo '# Test' >> README.md"
echo "   git add README.md && git commit -m 'Test OIDC'"
echo "   git push origin test-oidc"
echo "   Create a Pull Request and watch GitHub Actions"
echo ""
echo "4️⃣  Check workflow logs:"
echo "   Look for: 'Retrieving assume role credentials'"
echo "   This confirms OIDC is working!"
echo ""
echo -e "${GREEN}📚 For more info, see: docs/OIDC_SETUP.md${NC}"
echo ""
