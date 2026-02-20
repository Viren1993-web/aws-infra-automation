# DeployerAccess-Github IAM Policy Reference

> Custom inline policy `DeployerAccessPolicy` on the `DeployerAccess-Github` role — least-privilege, no managed-policy bloat.

---

## Full Policy JSON

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:GetRole", "iam:CreateRole", "iam:UpdateRole",
        "iam:AttachRolePolicy", "iam:DetachRolePolicy",
        "iam:PutRolePolicy", "iam:GetRolePolicy", "iam:DeleteRolePolicy",
        "iam:ListRolePolicies", "iam:ListAttachedRolePolicies",
        "iam:CreatePolicy", "iam:GetPolicy",
        "iam:ListPolicyVersions", "iam:CreatePolicyVersion",
        "iam:PassRole"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*", "lambda:*", "dynamodb:*",
        "application-autoscaling:*", "apigateway:*",
        "cloudfront:*", "sns:*", "ec2:*",
        "logs:*", "cloudwatch:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["sts:GetCallerIdentity"],
      "Resource": "*"
    }
  ]
}
```

---

## Permission → Purpose

| Service | Actions | Used For |
|---------|---------|----------|
| **IAM** | Specific create/get/attach/pass | Manage Lambda execution role & policies |
| **S3** | `s3:*` | Website hosting, bucket management |
| **Lambda** | `lambda:*` | Deploy & manage functions |
| **DynamoDB** | `dynamodb:*` | Create/manage tables |
| **Auto Scaling** | `application-autoscaling:*` | DynamoDB read/write capacity scaling |
| **API Gateway** | `apigateway:*` | HTTP API for Lambda |
| **CloudFront** | `cloudfront:*` | CDN distribution |
| **SNS** | `sns:*` | Alert topics |
| **EC2/VPC** | `ec2:*` | VPC, subnets, security groups, IGW |
| **CloudWatch** | `logs:*`, `cloudwatch:*` | Log groups, dashboards, alarms |
| **STS** | `sts:GetCallerIdentity` | Credential verification in tests |

---

## Security Notes

- **Custom inline > managed policies** — no unused permissions, easy to audit.
- **Future hardening:** replace `*` resources with specific ARNs (e.g., `arn:aws:s3:::aws-infra-automation-*/*`).

---

## CLI Commands

```bash
# View policy
aws iam get-role-policy --role-name DeployerAccess-Github --policy-name DeployerAccessPolicy

# List inline policies
aws iam list-role-policies --role-name DeployerAccess-Github

# Update policy
aws iam put-role-policy \
  --role-name DeployerAccess-Github \
  --policy-name DeployerAccessPolicy \
  --policy-document file://policy.json
```
