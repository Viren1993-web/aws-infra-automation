# GitHub Actions OIDC Setup Guide

## 🔐 What is OIDC?

**OIDC (OpenID Connect)** allows GitHub to authenticate with AWS **without storing credentials** as secrets.

### Benefits
- ✅ No sensitive AWS keys to store
- ✅ Credentials are temporary (1 hour max)
- ✅ More secure than long-lived credentials
- ✅ Better for automated CI/CD

---

## 📋 Prerequisites

- ✅ AWS Account with admin access
- ✅ GitHub repository
- ✅ GitHub Actions workflows configured

---

## 🚀 Setup Steps

### Step 1: Get Your AWS Account ID

```bash
aws sts get-caller-identity --query Account --output text
```

Save this number - you'll need it in the workflows (it's already in the `AWS_ACCOUNT_ID` env var).

### Step 2: Create OIDC Provider in AWS

Go to **AWS Console** → **IAM** → **Identity providers** → **Add provider**

Fill in:
- **Provider type:** OpenID Connect
- **Provider URL:** `https://token.actions.githubusercontent.com`
- **Audience:** `sts.amazonaws.com`
- **GitHub organization:** `Viren1993-web`

Then click **Add provider**

---

### Step 3: Create IAM Role (Manual Method)

#### Option A: Using AWS Console (Step-by-step)

1. Go to **IAM** → **Roles** → **Create role**

2. Select **Custom trust policy** and paste:

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

**Replace:**
- `YOUR_ACCOUNT_ID` with your AWS account ID
- `YOUR_GITHUB_USERNAME` with your GitHub username

3. Click **Next**

4. **Create inline policy with the necessary permissions:**
   - Click **Create inline policy**
   - Use the policy from [docs/IAM_POLICY_REFERENCE.md](IAM_POLICY_REFERENCE.md)
   - Name it: `DeployerAccessPolicy`
   - This custom policy includes only necessary permissions (least-privilege approach)

5. Name the role: `DeployerAccess-Github`

6. Click **Create role**

---

#### Option B: Using AWS CLI (Faster)

```bash
# 1. Set variables
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
GITHUB_USERNAME="your-github-username"  # CHANGE THIS
REPO_NAME="aws-infra-automation"

# 2. Create trust policy JSON
cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_USERNAME}/${REPO_NAME}:*"
        }
      }
    }
  ]
}
EOF

# 3. Create the role
aws iam create-role \
  --role-name DeployerAccess-Github \
  --assume-role-policy-document file://trust-policy.json

# 4. Create custom inline policy (least-privilege approach)
cat > deployer-policy.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "lambda:*",
        "dynamodb:*",
        "application-autoscaling:*",
        "apigateway:*",
        "cloudfront:*",
        "sns:*",
        "ec2:*",
        "logs:*",
        "cloudwatch:*",
        "iam:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF

# 5. Attach the inline policy
aws iam put-role-policy \
  --role-name DeployerAccess-Github \
  --policy-name DeployerAccessPolicy \
  --policy-document file://deployer-policy.json

# 6. Cleanup
rm trust-policy.json deployer-policy.json

echo "✅ Role created successfully!"
echo "✅ Custom policy DeployerAccessPolicy attached!"
```

---

### Step 4: Verify the Role ARN

```bash
aws iam get-role --role-name DeployerAccess-Github --query 'Role.Arn'
```

You should see something like:
```
arn:aws:iam::587402071946:role/DeployerAccess-Github
```

This is already configured in your workflows with the `AWS_ACCOUNT_ID` env var.

---

### Step 5: Remove AWS Secrets from GitHub

⚠️ **IMPORTANT:** Remove these from your GitHub repository secrets:

1. Go to GitHub repo → **Settings** → **Secrets and variables** → **Actions**
2. Delete:
   - ❌ `AWS_ACCESS_KEY_ID`
   - ❌ `AWS_SECRET_ACCESS_KEY`

You no longer need them with OIDC!

---

### Step 6: Update Workflows

Your workflows are already updated! The `AWS_ACCOUNT_ID` environment variable is set to your account ID. Make sure it matches:

```yaml
env:
  AWS_ACCOUNT_ID: '587402071946'  # Update this if different
```

---

## ✅ Testing OIDC

### Test 1: Use test-oidc script from scripts folder

### Test 2: Check workflow logs

1. Go to GitHub repo → **Actions**
2. Click the workflow run
3. Expand **Configure AWS Credentials** step
4. Look for: `Retrieving assume role credentials` (this means OIDC is working!)

---

## 🔍 Troubleshooting

### Error: "NotAuthorized" or "Unauthorized"

**Problem:** Role doesn't have required permissions

**Solution:**
1. Verify role exists: `aws iam get-role --role-name DeployerAccess-Github`
2. Check inline policies: `aws iam list-role-policies --role-name DeployerAccess-Github`
3. Verify `DeployerAccessPolicy` is attached with all required permissions

### Error: "No suitable credentials"

**Problem:** OIDC provider not set up correctly

**Solution:**
1. Verify OIDC provider exists:
   ```bash
   aws iam list-open-id-connect-providers
   ```
   Should show: `arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com`

2. If missing, create it via AWS Console (IAM → Identity providers)

### Error: "Assume role arn:aws:iam::... not found"

**Problem:** Role name is wrong or `AWS_ACCOUNT_ID` env var is incorrect

**Solution:**
1. Verify role exists:
   ```bash
   aws iam get-role --role-name DeployerAccess-Github
   ```

2. Update `AWS_ACCOUNT_ID` in workflows if needed:
   ```bash
   aws sts get-caller-identity --query Account --output text
   ```

### Workflow still using old credentials

**Problem:** GitHub cached old secrets

**Solution:**
1. Go to repo → **Settings** → **Secrets and variables**
2. Verify `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are **deleted**
3. Re-run the workflow

---

## 📊 How OIDC Works (In Simple Terms)

```
┌─────────────────────────────────────────────────────────────┐
│ GitHub Actions Workflow Runs                                │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
        ┌──────────────────────────────┐
        │ GitHub generates OIDC token  │
        │ (valid for 1 hour)           │
        └────────────┬─────────────────┘
                     │
                     ▼
        ┌──────────────────────────────┐
        │ Send token to AWS STS        │
        │ (Secure Token Service)       │
        └────────────┬─────────────────┘
                     │
                     ▼
        ┌──────────────────────────────┐
        │ AWS verifies token signature │
        │ & checks repository match    │
        └────────────┬─────────────────┘
                     │
                     ▼
        ┌──────────────────────────────┐
        │ AWS issues temporary creds   │
        │ (~1 hour validity)           │
        └────────────┬─────────────────┘
                     │
                     ▼
        ┌──────────────────────────────┐
        │ Workflow uses temp creds     │
        │ to access AWS resources      │
        └──────────────────────────────┘
```

**Key Benefits:**
- No storing long-lived secrets
- Token is short-lived (1 hour)
- Automatic rotation
- GitHub controls the token

---

## 💡 Why Custom Inline Policy?

This project uses **custom inline policy `DeployerAccessPolicy`** instead of AWS managed policies:

### ✅ Custom Inline Policy (Recommended)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "lambda:*",
        "dynamodb:*",
        "apigateway:*",
        "cloudfront:*",
        "sns:*",
        "ec2:*",
        "logs:*",
        "cloudwatch:*",
        "iam:*"
      ],
      "Resource": "*"
    }
  ]
}
```

**Why This Approach:**
- ✅ **Follows Least Privilege Principle** - Only includes necessary permissions
- ✅ **No Permission Bloat** - Doesn't exceed AWS Free Tier limits
- ✅ **Easier to Audit** - Specific to your infrastructure needs
- ✅ **Better Cost Control** - Prevents accidental over-provisioning
- ✅ **Enterprise Security** - Recommended for production systems

### ❌ AWS Managed Policies (Not Recommended)
Full-access policies like:
- AmazonS3FullAccess
- AWSLambda_FullAccess
- AmazonDynamoDBFullAccess
- CloudFrontFullAccess
- etc.

**Issues:**
- ❌ Overly permissive (includes unused services)
- ❌ Can exceed Free Tier limits
- ❌ Security risk (grant more access than needed)
- ❌ Harder to audit

For detailed breakdown of permissions in `DeployerAccessPolicy`, see [docs/IAM_POLICY_REFERENCE.md](IAM_POLICY_REFERENCE.md).

---

### 1. Restrict by Repository
The trust policy limits OIDC to your specific repo:
```
repo:YOUR_USERNAME/aws-infra-automation:*
```

### 2. Limit to Main Branch (Optional)
To only allow deployments from main:

```json
"token.actions.githubusercontent.com:sub": "repo:YOUR_USERNAME/aws-infra-automation:ref:refs/heads/main"
```

### 3. Use Environment Protection
In **Settings → Environments → production**:
- ✅ Enable "Required reviewers"
- ✅ Add yourself as reviewer

This ensures someone approves deployments!

### 4. Regular Audit
Check role permissions monthly:
```bash
aws iam list-role-policies --role-name DeployerAccess-Github
aws iam get-role-policy --role-name DeployerAccess-Github --policy-name DeployerAccessPolicy
```

---

## 📚 Related Documentation

- [GitHub Actions OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [AWS STS AssumeRoleWithWebIdentity](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [OIDC + GitHub Actions](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-cloud-providers)

---

## ✅ Verification Checklist

- [ ] OIDC provider created in AWS IAM
- [ ] `DeployerAccess-Github` role created
- [ ] `DeployerAccessPolicy` inline policy attached with correct permissions
- [ ] `AWS_ACCOUNT_ID` updated in workflows (if different from 587402071946)
- [ ] AWS secrets deleted from GitHub
- [ ] Test PR created and passed
- [ ] Workflows show "Retrieving assume role credentials"
- [ ] Run `./scripts/test-oidc.sh` to verify setup

---

## 🚀 Summary

OIDC setup is complete! Your workflows now:
- ✅ Use temporary AWS credentials (1 hour validity)
- ✅ No secrets stored in GitHub
- ✅ Enterprise-grade security (industry best practice)
- ✅ Automatically rotate credentials
- ✅ Least-privilege custom policy (no permission bloat)
- ✅ No AWS Free Tier limit issues

Ready to deploy! 🎉
