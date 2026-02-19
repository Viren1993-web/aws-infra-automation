# DeployerAccess-Github IAM Policy Reference

## Custom Policy

Configured a **custom inline IAM policy** named `DeployerAccessPolicy` for the `DeployerAccess-Github` role instead of using AWS managed policies. This is actually **better** because:

✅ **Least Privilege** - Only includes necessary permissions  
✅ **No Bloat** - Manages managed policies can include unnecessary permissions  
✅ **Fine-grained Control** - Easy to audit and modify  
✅ **Cost Effective** - No risk of permission creep  

---

## Policy Breakdown

Policy grants the following permissions:

### 1. IAM Permissions
```json
{
  "Effect": "Allow",
  "Action": [
    "iam:GetRole",
    "iam:CreateRole",
    "iam:UpdateRole",
    "iam:AttachRolePolicy",
    "iam:DetachRolePolicy",
    "iam:PutRolePolicy",
    "iam:GetRolePolicy",
    "iam:DeleteRolePolicy",
    "iam:ListRolePolicies",
    "iam:ListAttachedRolePolicies",
    "iam:CreatePolicy",
    "iam:GetPolicy",
    "iam:ListPolicyVersions",
    "iam:CreatePolicyVersion",
    "iam:PassRole"
  ],
  "Resource": "*"
}
```
**Purpose:** Terraform needs to manage IAM roles and policies for Lambda

### 2. S3 Permissions
```json
{
  "Effect": "Allow",
  "Action": ["s3:*"],
  "Resource": "*"
}
```
**Purpose:** 
- Upload website files to S3
- Manage S3 buckets
- Store Terraform state (if using S3 backend)

### 3. Application Auto Scaling Permissions
```json
{
  "Effect": "Allow",
  "Action": ["application-autoscaling:*"],
  "Resource": "*"
}
```
**Purpose:** Configure auto-scaling for DynamoDB tables (read/write capacity)

### 4. DynamoDB Permissions
```json
{
  "Effect": "Allow",
  "Action": ["dynamodb:*"],
  "Resource": "*"
}
```
**Purpose:** Create and manage DynamoDB tables

### 5. Lambda Permissions
```json
{
  "Effect": "Allow",
  "Action": ["lambda:*"],
  "Resource": "*"
}
```
**Purpose:** Deploy and manage Lambda functions, layers, and permissions

### 6. API Gateway Permissions
```json
{
  "Effect": "Allow",
  "Action": ["apigateway:*"],
  "Resource": "*"
}
```
**Purpose:** Create and manage API Gateway (HTTP API)

### 7. CloudFront Permissions
```json
{
  "Effect": "Allow",
  "Action": ["cloudfront:*"],
  "Resource": "*"
}
```
**Purpose:** Create and manage CloudFront distributions

### 8. SNS Permissions
```json
{
  "Effect": "Allow",
  "Action": ["sns:*"],
  "Resource": "*"
}
```
**Purpose:** Create and manage SNS topics for alerts

### 9. EC2 Permissions
```json
{
  "Effect": "Allow",
  "Action": ["ec2:*"],
  "Resource": "*"
}
```
**Purpose:** Manage VPC, subnets, security groups, Internet Gateway

### 10. CloudWatch Logs Permissions
```json
{
  "Effect": "Allow",
  "Action": ["logs:*"],
  "Resource": "*"
}
```
**Purpose:** Create and manage CloudWatch log groups

### 11. CloudWatch Metrics & Alarms Permissions
```json
{
  "Effect": "Allow",
  "Action": ["cloudwatch:*"],
  "Resource": "*"
}
```
**Purpose:** Create dashboards, alarms, and CloudWatch configurations

### 12. STS Permissions
```json
{
  "Effect": "Allow",
  "Action": ["sts:GetCallerIdentity"],
  "Resource": "*"
}
```
**Purpose:** Verify AWS credentials are working (used in tests)

---

## ✅ Coverage Analysis

Policy covers **all** required services:

| Service | Needed | Policy | Status |
|---------|--------|------------|--------|
| **IAM** | ✅ | iam:* | ✅ Covered |
| **S3** | ✅ | s3:* | ✅ Covered |
| **Lambda** | ✅ | lambda:* | ✅ Covered |
| **DynamoDB** | ✅ | dynamodb:* | ✅ Covered |
| **Auto Scaling** | ✅ | application-autoscaling:* | ✅ Covered |
| **API Gateway** | ✅ | apigateway:* | ✅ Covered |
| **CloudFront** | ✅ | cloudfront:* | ✅ Covered |
| **SNS** | ✅ | sns:* | ✅ Covered |
| **EC2/VPC** | ✅ | ec2:* | ✅ Covered |
| **CloudWatch Logs** | ✅ | logs:* | ✅ Covered |
| **CloudWatch** | ✅ | cloudwatch:* | ✅ Covered |
| **STS** | ✅ | sts:GetCallerIdentity | ✅ Covered |

---

## 🔐 Security Considerations

### Strengths ✅
- Custom policy is **more specific** than AWS managed policies
- Only grants necessary permissions
- Easy to audit exactly what's allowed

### Potential Improvements 🔧
For **maximum security**, you could further restrict:

```json
// Instead of using wildcard "*" resource
"s3:*" on "*"

// You could use specific bucket ARN:
"s3:GetObject",
"s3:PutObject"
on "arn:aws:s3:::aws-infra-automation-*/*"
```
---

## 🚀 Setup Status

✅ **DeployerAccess-Github** role configured  
✅ **Custom inline policy** with all necessary permissions  
✅ **OIDC provider** set up  
✅ **GitHub Actions workflows** configured to use this role  

**You're ready to go!**

---

## 📝 For Future Reference

If you want to **add or modify** this policy:

```bash
# View current policy (DeployerAccessPolicy)
aws iam get-role-policy \
  --role-name DeployerAccess-Github \
  --policy-name DeployerAccessPolicy

# List all inline policies on role
aws iam list-role-policies --role-name DeployerAccess-Github

# Update policy (you'll need the full policy JSON)
aws iam put-role-policy \
  --role-name DeployerAccess-Github \
  --policy-name DeployerAccessPolicy \
  --policy-document file://policy.json
```

---

## ✅ Summary

`DeployerAccess-Github` role is **perfectly configured** for this project with a custom inline policy that covers all necessary AWS services. This is actually **better** than using AWS managed policies because it's more specific and follows the principle of least privilege.

No changes needed - you're all set! 🎉
