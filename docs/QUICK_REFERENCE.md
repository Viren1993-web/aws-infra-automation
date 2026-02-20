# Quick Reference

> **Cheat sheet for everyday commands.** For full guides see [Deployment](DEPLOYMENT.md) · [GitHub Actions](GITHUB_ACTIONS_GUIDE.md) · [OIDC Setup](OIDC_SETUP.md)

---

## Project Scripts

```bash
./scripts/deploy.sh        # deploy everything (Terraform + S3 upload + CDN invalidation)
./scripts/test-api.sh      # test all CRUD endpoints
./scripts/test-oidc.sh     # set up / verify OIDC for GitHub Actions
./scripts/destroy.sh       # tear down all resources
```

---

## Terraform

```bash
cd terraform
terraform init             # download providers
terraform validate         # check syntax
terraform fmt -recursive   # auto-format
terraform plan             # preview changes
terraform apply            # deploy
terraform destroy          # tear down
terraform output           # show all outputs
terraform state list       # list managed resources
```

### Get specific outputs
```bash
terraform output -raw api_gateway_url
terraform output -raw cloudfront_domain
terraform output -raw s3_bucket_name
```

---

## AWS CLI — Resource Commands

### S3
```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET="aws-infra-automation-website-${ACCOUNT_ID}"

aws s3 sync website/ s3://${BUCKET}/           # upload website
aws s3 ls s3://${BUCKET}/                      # list files
aws s3 rm s3://${BUCKET}/ --recursive          # empty bucket
```

### CloudFront
```bash
DIST_ID=$(aws cloudfront list-distributions \
  --query "DistributionList.Items[?Comment=='aws-infra-automation CDN'].Id" --output text)

aws cloudfront create-invalidation --distribution-id ${DIST_ID} --paths "/*"
aws cloudfront get-distribution --id ${DIST_ID} --query 'Distribution.Status'
```

### Lambda
```bash
aws logs tail /aws/lambda/aws-infra-automation-api-handler --follow   # live logs
aws logs tail /aws/lambda/aws-infra-automation-api-handler --since 1h # last hour
```

### DynamoDB
```bash
aws dynamodb scan --table-name aws-infra-automation-data              # all items
aws dynamodb describe-table --table-name aws-infra-automation-data \
  --query 'Table.ItemCount'                                           # item count
```

### CloudWatch
```bash
# alarm states
aws cloudwatch describe-alarms \
  --query 'MetricAlarms[?starts_with(AlarmName, `aws-infra-automation`)].{Name:AlarmName,State:StateValue}'
```

---

## API Testing (curl)

```bash
API_URL=$(cd terraform && terraform output -raw api_gateway_url)

curl "${API_URL}/"                                                    # GET all
curl -X POST "${API_URL}/" -H "Content-Type: application/json" \
  -d '{"id":"test-1","status":"active","data":{"title":"Hello"}}'     # CREATE
curl "${API_URL}/?id=test-1"                                          # GET one
curl -X PUT "${API_URL}/" -H "Content-Type: application/json" \
  -d '{"id":"test-1","timestamp":1234567890,"status":"updated","data":{"title":"Updated"}}' # UPDATE
curl -X DELETE "${API_URL}/?id=test-1&timestamp=1234567890"           # DELETE
```

---

## Troubleshooting

| Problem | Quick fix |
|---------|-----------|
| "Access Denied" | `aws sts get-caller-identity` — check you're using the right account |
| Terraform state locked | `terraform force-unlock <LOCK_ID>` |
| S3 won't delete (not empty) | `aws s3 rm s3://${BUCKET}/ --recursive` then retry |
| CloudFront stuck "Deploying" | Normal (15-20 min). Use S3 URL for testing in the meantime |
| Lambda not updating | `terraform taint aws_lambda_function.api_handler && terraform apply` |
| CORS errors | Check API Gateway CORS config in `terraform/lambda.tf`, then `terraform apply` |

---

## Useful Aliases

Add to `~/.zshrc` or `~/.bashrc`:

```bash
alias deploy='./scripts/deploy.sh'
alias testapi='./scripts/test-api.sh'
alias tfinit='terraform init'
alias tfplan='terraform plan'
alias tfapply='terraform apply'
alias lambdalogs='aws logs tail /aws/lambda/aws-infra-automation-api-handler --follow'
```
