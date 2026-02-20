# GitHub Actions OIDC Setup Guide

> OIDC lets GitHub authenticate with AWS using **temporary credentials** — no stored secrets needed.

---

## Prerequisites

- AWS account with admin access
- GitHub repository with Actions enabled

---

## Setup Steps

### 1. Create OIDC Provider

**AWS Console:** IAM → Identity providers → Add provider

| Field | Value |
|-------|-------|
| Provider type | OpenID Connect |
| Provider URL | `https://token.actions.githubusercontent.com` |
| Audience | `sts.amazonaws.com` |

### 2. Create IAM Role

**Option A — Console:**

1. IAM → Roles → Create role → **Custom trust policy**
2. Paste trust policy below, replacing placeholders
3. Add inline policy `DeployerAccessPolicy` from [IAM_POLICY_REFERENCE.md](IAM_POLICY_REFERENCE.md)
4. Name: `DeployerAccess-Github`

**Trust policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/aws-infra-automation:*"
        }
      }
    }
  ]
}
```

**Option B — CLI:**
```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
GITHUB_USERNAME="your-github-username"

# Create trust policy file
cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": { "token.actions.githubusercontent.com:aud": "sts.amazonaws.com" },
      "StringLike": { "token.actions.githubusercontent.com:sub": "repo:${GITHUB_USERNAME}/aws-infra-automation:*" }
    }
  }]
}
EOF

# Create role + attach inline policy
aws iam create-role --role-name DeployerAccess-Github --assume-role-policy-document file://trust-policy.json
aws iam put-role-policy --role-name DeployerAccess-Github --policy-name DeployerAccessPolicy --policy-document file://deployer-policy.json
rm trust-policy.json
```

> For the full `deployer-policy.json` content, see [IAM_POLICY_REFERENCE.md](IAM_POLICY_REFERENCE.md).

### 3. Verify

```bash
aws iam get-role --role-name DeployerAccess-Github --query 'Role.Arn'
# Expected: arn:aws:iam::587402071946:role/DeployerAccess-Github
```

### 4. Remove Old Secrets from GitHub

Go to repo → Settings → Secrets → Actions and **delete** `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` — they're no longer needed.

### 5. Confirm Workflow Config

Workflows use `AWS_ACCOUNT_ID` env var — verify it matches your account:
```yaml
env:
  AWS_ACCOUNT_ID: '587402071946'
```

---

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `NotAuthorized` | Missing permissions | Check `DeployerAccessPolicy` exists: `aws iam list-role-policies --role-name DeployerAccess-Github` |
| `No suitable credentials` | OIDC provider missing | Verify: `aws iam list-open-id-connect-providers` |
| `Role ... not found` | Wrong role name or account ID | Verify: `aws iam get-role --role-name DeployerAccess-Github` |
| Still using old creds | Cached GitHub secrets | Delete `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` from repo secrets |

---

## Security Best Practices

| Practice | How |
|----------|-----|
| Restrict by repo | Already done — trust policy limits to `repo:YOUR_USERNAME/aws-infra-automation:*` |
| Restrict to main branch | Change trust condition `sub` to `...aws-infra-automation:ref:refs/heads/main` |
| Require approval | Settings → Environments → production → Required reviewers |
| Audit regularly | `aws iam get-role-policy --role-name DeployerAccess-Github --policy-name DeployerAccessPolicy` |

---

## Verification Checklist

- [ ] OIDC provider created in AWS IAM
- [ ] `DeployerAccess-Github` role created with trust policy
- [ ] `DeployerAccessPolicy` inline policy attached ([reference](IAM_POLICY_REFERENCE.md))
- [ ] `AWS_ACCOUNT_ID` correct in workflows
- [ ] Old AWS secrets deleted from GitHub
- [ ] Workflow shows "Retrieving assume role credentials"
- [ ] `./scripts/test-oidc.sh` passes

---

## Resources

- [GitHub OIDC Docs](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [AWS OIDC Configuration](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
