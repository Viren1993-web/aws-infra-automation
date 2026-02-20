# Deployment Guide

> **Related docs:** [README](../README.md) · [OIDC Setup](OIDC_SETUP.md) · [GitHub Actions Guide](GITHUB_ACTIONS_GUIDE.md) · [IAM Policy Reference](IAM_POLICY_REFERENCE.md) · [Quick Reference](QUICK_REFERENCE.md)

---

## Prerequisites

| Tool | Install (macOS) | Install (Linux) | Verify |
|------|----------------|-----------------|--------|
| AWS CLI | `brew install awscli` | [AWS docs](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) | `aws --version` |
| Terraform | `brew install hashicorp/tap/terraform` | [Terraform docs](https://developer.hashicorp.com/terraform/install) | `terraform --version` |
| Git | `brew install git` | `sudo apt install git` | `git --version` |

**AWS credentials:**
```bash
aws configure          # enter Access Key, Secret Key, region: us-east-1, output: json
aws sts get-caller-identity   # verify it works
```

> Need an IAM user? Go to AWS Console → IAM → Users → Add user → Attach `AdministratorAccess` → Save keys.

---

## Deploy (Two Methods)

### Method A: Local (one command)

```bash
# 1. Configure
cd terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars                      # set alert_email = "you@email.com"

# 2. Deploy everything
cd ..
./scripts/deploy.sh                        # ~20 min (CloudFront is slowest)

# 3. Check your email and confirm the SNS subscription

# 4. Update website with your API URL
cd terraform && terraform output api_gateway_url
# Edit website/index.html → replace YOUR_API_GATEWAY_URL_HERE with the URL above
cd .. && ./scripts/deploy.sh               # re-upload
```

Your outputs:
```bash
cd terraform
terraform output cloudfront_domain         # website URL
terraform output api_gateway_url           # API endpoint
```

### Method B: CI/CD (push to GitHub)

First-time setup:
```bash
# 1. Push code to GitHub
git remote add origin https://github.com/YOUR_USERNAME/aws-infra-automation.git
git push -u origin main

# 2. Set up OIDC (no stored AWS credentials!)
./scripts/test-oidc.sh

# 3. Update AWS_ACCOUNT_ID in both workflow files:
#    .github/workflows/terraform-ci.yml
#    .github/workflows/terraform-cd.yml
```

After that, everything is automated:
- **Push to `main`** → CD deploys (Terraform apply → S3 upload → CloudFront invalidation)
- **Open a PR** → CI validates (format check, lint, plan, security scan, posts plan as PR comment)
- **Manual trigger** → GitHub → Actions → "Terraform CD (Deploy)" → Run workflow

> Full walkthrough: [GitHub Actions Guide](GITHUB_ACTIONS_GUIDE.md) · [OIDC Setup](OIDC_SETUP.md)

---

## Post-Deployment Checks

Quick verification:
```bash
./scripts/test-api.sh                      # tests all CRUD operations
```

Check resources exist:
```bash
aws s3 ls | grep aws-infra-automation
aws lambda list-functions --query 'Functions[?starts_with(FunctionName, `aws-infra-automation`)].FunctionName'
aws dynamodb list-tables --query 'TableNames[?contains(@, `aws-infra-automation`)]'
```

CloudWatch dashboard: AWS Console → CloudWatch → Dashboards → `aws-infra-automation-dashboard`

> Full list of verification commands: [Quick Reference](QUICK_REFERENCE.md)

---

## Making Changes

| What changed | Local | CI/CD (recommended) |
|-------------|-------|---------------------|
| Terraform files | `terraform plan` → `terraform apply` | Push to main → auto-deploys |
| Lambda code | `terraform apply` (auto-redeploys) | Push to main → auto-deploys |
| Website files | `./scripts/deploy.sh` | Push to main → auto-uploads + CDN invalidation |

CI/CD is recommended — you get automated validation, PR plan comments, and a full audit trail.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Terraform AWS Provider error | Run `aws sts get-caller-identity` — credentials may be wrong |
| S3 BucketAlreadyExists | Bucket names are global; change `project_name` in `variables.tf` |
| CloudFront seems stuck | Normal — takes 15-20 min. Check: `aws cloudfront list-distributions --query 'DistributionList.Items[].Status'` |
| CORS errors from API | Check CORS config in `terraform/lambda.tf` |
| Website returns 403 | Check S3 bucket policy and CloudFront OAC |
| OIDC "Not authorized" | Verify provider exists in IAM, trust policy has your repo, `AWS_ACCOUNT_ID` matches. Re-run `./scripts/test-oidc.sh` |
| CI fails on plan | Run `terraform fmt -recursive` and `terraform validate` locally first |
| CD fails on apply | Check IAM permissions ([IAM Policy Reference](IAM_POLICY_REFERENCE.md)), try `terraform apply` locally |

---

## Backup & Teardown

```bash
# Backup DynamoDB
aws dynamodb scan --table-name aws-infra-automation-data > dynamodb-backup.json

# Backup Terraform state
cd terraform && terraform show -json > terraform-state-backup.json

# Destroy everything
./scripts/destroy.sh
```

---

## Cost Monitoring

Everything runs at **$0/month** on Free Tier, but set up a billing alarm just in case:

1. AWS Console → Billing → Billing Preferences → Enable "Receive Billing Alerts"
2. CloudWatch → Alarms → Billing → Create alarm for charges > $1

---

## What's Next

**Already built:** CI/CD pipeline, OIDC auth, monitoring (6 alarms + dashboard), CRUD API, global CDN, full docs

**Future ideas:** Custom domain (Route 53) · User auth (Cognito) · Staging environment · Grafana · Remote state backend (S3 + DynamoDB lock)

---

## All Project Docs

| Document | What's in it |
|----------|-------------|
| [README.md](../README.md) | Architecture, features, quick start, testing |
| [OIDC_SETUP.md](OIDC_SETUP.md) | OIDC provider + IAM role setup |
| [GITHUB_ACTIONS_GUIDE.md](GITHUB_ACTIONS_GUIDE.md) | CI/CD pipeline details |
| [IAM_POLICY_REFERENCE.md](IAM_POLICY_REFERENCE.md) | Roles, policies, permissions |
| [QUICK_REFERENCE.md](QUICK_REFERENCE.md) | Command cheat sheet |
| [BITBUCKET_VS_GITHUB.md](BITBUCKET_VS_GITHUB.md) | Bitbucket → GitHub comparison |
| [LINKEDIN_GUIDE.md](LINKEDIN_GUIDE.md) | LinkedIn post templates |
| [LINKEDIN_PROJECT_SETUP.md](LINKEDIN_PROJECT_SETUP.md) | Adding project to LinkedIn profile |

---

Happy deploying! 🚀
