#!/bin/bash

# Test Script for API Gateway endpoints
# This script tests all API endpoints

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get API URL from Terraform output
cd terraform
API_URL=$(terraform output -raw api_gateway_url 2>/dev/null)
cd ..

if [ -z "$API_URL" ] || [ "$API_URL" == "null" ]; then
    echo -e "${RED}❌ Could not get API Gateway URL. Make sure infrastructure is deployed.${NC}"
    exit 1
fi

echo -e "${BLUE}🧪 Testing API Endpoints${NC}"
echo -e "${BLUE}API URL: ${GREEN}${API_URL}${NC}"
echo "=============================================="

# Test 1: GET all items
echo -e "\n${YELLOW}Test 1: GET all items${NC}"
curl -s -X GET "${API_URL}/" | jq '.' || echo -e "${RED}Failed${NC}"

# Test 2: POST create item
echo -e "\n${YELLOW}Test 2: POST create item${NC}"
ITEM_ID="test-$(date +%s)"
TIMESTAMP=$(date +%s)
curl -s -X POST "${API_URL}/" \
  -H "Content-Type: application/json" \
  -d "{
    \"id\": \"${ITEM_ID}\",
    \"timestamp\": ${TIMESTAMP},
    \"status\": \"active\",
    \"data\": {
      \"title\": \"Test Item\",
      \"description\": \"Created via script\"
    }
  }" | jq '.' || echo -e "${RED}Failed${NC}"

# Test 3: GET single item
echo -e "\n${YELLOW}Test 3: GET single item${NC}"
curl -s -X GET "${API_URL}/?id=${ITEM_ID}" | jq '.' || echo -e "${RED}Failed${NC}"

# Test 4: PUT update item
echo -e "\n${YELLOW}Test 4: PUT update item${NC}"
curl -s -X PUT "${API_URL}/" \
  -H "Content-Type: application/json" \
  -d "{
    \"id\": \"${ITEM_ID}\",
    \"timestamp\": ${TIMESTAMP},
    \"status\": \"updated\",
    \"data\": {
      \"title\": \"Updated Test Item\",
      \"description\": \"Updated via script\"
    }
  }" | jq '.' || echo -e "${RED}Failed${NC}"

# Test 5: DELETE item
echo -e "\n${YELLOW}Test 5: DELETE item${NC}"
curl -s -X DELETE "${API_URL}/?id=${ITEM_ID}&timestamp=${TIMESTAMP}" | jq '.' || echo -e "${RED}Failed${NC}"

echo -e "\n${GREEN}✅ All tests completed!${NC}"
