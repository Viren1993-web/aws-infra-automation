# AWS Infrastructure Automation - Serverless Portfolio

## Overview
This project demonstrates the provisioning and management of a **production-ready serverless AWS environment** using **Terraform**. Built entirely with AWS Free Tier resources, it showcases modern cloud architecture, **Infrastructure as Code (IaC)** best practices, automation, monitoring, and security.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         CloudFront CDN                       │
│              (1TB data transfer/month - FREE)                │
└────────────────────────┬────────────────────────────────────┘
                         │
         ┌───────────────┴────────────────┐
         │                                │
┌────────▼────────┐              ┌───────▼────────┐
│   S3 Website    │              │  API Gateway   │
│  (Static HTML)  │              │  (HTTP API)    │
│   5GB - FREE    │              │  1M req - FREE │
└─────────────────┘              └───────┬────────┘
                                         │
                                 ┌───────▼────────┐
                                 │  Lambda        │
                                 │  Python 3.11   │
                                 │  1M req - FREE │
                                 └───────┬────────┘
                                         │
                         ┌───────────────┴──────────────┐
                         │                              │
                ┌────────▼─────────┐          ┌────────▼─────────┐
                │    DynamoDB      │          │   CloudWatch     │
                │  25GB/25RCU/WCU  │          │  10 Alarms       │
                │      FREE        │          │      FREE        │
                └──────────────────┘          └────────┬─────────┘
                                                       │
                                              ┌────────▼─────────┐
                                              │   SNS Topics     │
                                              │  1M pub - FREE   │
                                              └──────────────────┘
```

## 💰 Cost Optimization
**Monthly Cost: $0.00** (100% Free Tier)

All resources are carefully selected to stay within AWS Always Free tier limits:
- **Lambda**: 1M requests + 400K GB-seconds/month
- **DynamoDB**: 25GB storage, 25 RCU, 25 WCU
- **S3**: 5GB storage, 20K GET, 2K PUT
- **CloudFront**: 1TB data transfer, 10M requests
- **API Gateway**: 1M calls/month
- **CloudWatch**: 10 alarms, 5GB logs
- **SNS**: 1M publishes, 1K emails
- **VPC**: Completely free (no NAT Gateway)

## 🛠️ Technologies
- **Cloud**: AWS (Lambda, API Gateway, DynamoDB, S3, CloudFront, VPC, IAM)
- **IaC**: Terraform 1.0+
- **Backend**: Python 3.11 (Lambda)
- **Frontend**: HTML/CSS/JavaScript
- **Monitoring**: CloudWatch, SNS
- **Version Control**: Git
- **Automation**: Bash scripting

## ✨ Features
- ✅ **100% Serverless** - No servers to manage, auto-scaling
- ✅ **Zero Cost** - Entirely within AWS Free Tier limits
- ✅ **Infrastructure as Code** - All resources defined in Terraform
- ✅ **Secure by Default** - IAM roles, encryption, HTTPS-only
- ✅ **Production Monitoring** - CloudWatch dashboards and alarms
- ✅ **Automated Deployment** - One-command deployment script
- ✅ **RESTful API** - Full CRUD operations via Lambda + API Gateway
- ✅ **Global CDN** - CloudFront distribution for low latency
- ✅ **NoSQL Database** - DynamoDB with auto-scaling
- ✅ **Email Alerts** - SNS notifications for critical events
- ✅ **GitHub Actions CI/CD** - Automated testing and deployment pipeline
- ✅ **Enterprise Security** - OIDC authentication with temporary tokens

## 📊 Project Impact
- **Architecture**: Modern serverless stack demonstrating cloud-native design
- **Automation**: 100% automated infrastructure provisioning and deployment
- **Scalability**: Auto-scales from 0 to production workloads seamlessly
- **Cost Efficiency**: Optimized for AWS Free Tier - $0/month running cost
- **Monitoring**: Real-time dashboards and proactive alerting
- **Security**: Best practices with IAM, encryption, and network isolation

## 🚀 Quick Start

### Prerequisites
- AWS Account (Free Tier)
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured
- [Terraform](https://www.terraform.io/downloads) 1.0 or later
- Bash shell (Linux/macOS/WSL)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/aws-infra-automation.git
cd aws-infra-automation
```

2. **Configure AWS credentials**
```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, and preferred region (us-east-1)
```

3. **Update variables** (Optional)
```bash
cd terraform
# Edit variables.tf to customize:
# - alert_email: Your email for CloudWatch alerts
# - aws_region: AWS region (default: us-east-1)
# - project_name: Project name prefix
```

4. **Deploy infrastructure**
```bash
cd ..
./scripts/deploy.sh
```

The script will:
- Initialize Terraform
- Create all AWS resources
- Upload website files to S3
- Display infrastructure outputs

5. **Confirm SNS subscription**
- Check your email for an SNS subscription confirmation
- Click the confirmation link to receive alerts

6. **Update API URL in website**
- Get the API Gateway URL from terraform outputs
- Update `website/index.html` with your API URL
- Re-run: `./scripts/deploy.sh`

7. **Access your application**
```bash
# Your CloudFront URL will be displayed after deployment
# Example: https://d1234567890.cloudfront.net
```

### Testing

Test the API endpoints:
```bash
./scripts/test-api.sh
```

Or manually:
```bash
# Get all items
curl https://your-api-url.execute-api.us-east-1.amazonaws.com/

# Create item
curl -X POST https://your-api-url.execute-api.us-east-1.amazonaws.com/ \
  -H "Content-Type: application/json" \
  -d '{"id":"test-1","status":"active","data":{"title":"Test"}}'

# Get single item
curl https://your-api-url.execute-api.us-east-1.amazonaws.com/?id=test-1

# Delete item
curl -X DELETE https://your-api-url.execute-api.us-east-1.amazonaws.com/?id=test-1
```

## 📁 Project Structure

```
aws-infra-automation/
├── README.md                    # This file
├── diagrams/                    # Architecture diagrams
├── lambda/                      # Lambda function code
│   └── index.py                # Python API handler
├── scripts/                     # Deployment scripts
│   ├── deploy.sh               # Main deployment script
│   ├── destroy.sh              # Infrastructure teardown
│   └── test-api.sh             # API testing script
├── terraform/                   # Terraform configurations
│   ├── main.tf                 # Provider configuration
│   ├── variables.tf            # Input variables
│   ├── outputs.tf              # Output values
│   ├── vpc.tf                  # VPC and networking
│   ├── s3.tf                   # S3 buckets
│   ├── lambda.tf               # Lambda functions
│   ├── dynamodb.tf             # DynamoDB tables
│   ├── cloudfront.tf           # CloudFront distribution
│   └── monitoring.tf           # CloudWatch & SNS
└── website/                     # Static website files
    ├── index.html              # Main page
    └── error.html              # Error page
```

## 🔧 Infrastructure Components

### Networking
- **VPC**: Custom VPC (10.0.0.0/16) with DNS enabled
- **Subnets**: 2 public subnets across 2 AZs for high availability
- **Internet Gateway**: For public internet access
- **Route Tables**: Public routing configuration
- **Security Groups**: Lambda egress rules

### Compute
- **Lambda Function**: Python 3.11 runtime, 128MB memory, 30s timeout
- **API Gateway**: HTTP API with CORS enabled
- **CloudWatch Logs**: 7-day retention for Lambda and API logs

### Storage
- **S3 Website Bucket**: Static website hosting with public read access
- **S3 State Bucket**: Terraform state with versioning and encryption
- **DynamoDB Table**: NoSQL database with auto-scaling enabled

### Content Delivery
- **CloudFront**: Global CDN with HTTPS redirect, custom error pages
- **Origin Access Control**: Secure S3 access from CloudFront

### Monitoring & Alerts
- **CloudWatch Alarms**: Lambda errors, duration, throttles, API 5XX errors
- **CloudWatch Dashboard**: Unified view of all metrics
- **SNS Topic**: Email notifications for critical alerts

### Security
- **IAM Roles**: Least-privilege access for Lambda
- **Encryption**: Server-side encryption for S3 and DynamoDB
- **HTTPS Only**: CloudFront enforces HTTPS
- **VPC**: Network isolation for resources

## 🎯 Use Cases

This infrastructure supports various serverless applications:

1. **RESTful API Backend**: Full CRUD API with Lambda + DynamoDB
2. **Static Website Hosting**: S3 + CloudFront for global delivery
3. **Microservices**: Scalable, event-driven architecture
4. **Data Processing**: Lambda for serverless data transformations
5. **Real-time Monitoring**: CloudWatch dashboards and alerting

## 🔐 Security Best Practices

- ✅ IAM roles with least-privilege permissions
- ✅ Encryption at rest (S3, DynamoDB)
- ✅ Encryption in transit (HTTPS only)
- ✅ VPC network isolation
- ✅ CloudWatch logging enabled
- ✅ No hardcoded credentials
- ✅ State file encryption
- ✅ S3 bucket versioning

## 📈 Monitoring

Access CloudWatch Dashboard:
1. Go to AWS Console → CloudWatch → Dashboards
2. Select `aws-infra-automation-dashboard`

Configured Alarms:
- Lambda function errors (threshold: 5 errors)
- Lambda duration (threshold: 25 seconds)
- Lambda throttles (threshold: 10)
- API Gateway 5XX errors (threshold: 10)
- DynamoDB capacity utilization (threshold: 80%)

## 🚀 GitHub Actions CI/CD Pipeline

This project includes automated CI/CD workflows with **enterprise-grade OIDC authentication**:

### Security Highlights
✅ **No AWS credentials stored in GitHub**
✅ **Temporary OIDC tokens (1 hour validity)**
✅ **Industry best practice**
✅ **Enterprise-grade security**

### Workflows

**Continuous Integration (terraform-ci.yml)**
- Runs on: Pull requests and pushes to main
- Validates Terraform formatting
- Checks Python code with linting
- Scans for security vulnerabilities (GitLeaks, tfsec)
- Posts Terraform plan as PR comment

**Continuous Deployment (terraform-cd.yml)**
- Runs on: Merges to main branch (or manual trigger)
- Automatically applies Terraform changes
- Uploads website to S3
- Invalidates CloudFront cache
- Provides deployment summary

### OIDC Authentication Setup

Instead of storing long-lived AWS credentials:
1. GitHub generates a temporary token (1 hour validity)
2. AWS STS exchanges the token for temporary credentials
3. Credentials are auto-revoked after use

This approach is recommended by:
- AWS (official documentation)
- OIDF (OpenID Foundation)
- Enterprise security teams worldwide

**To verify OIDC setup:**
```bash
./scripts/setup-oidc.sh
```

For detailed setup instructions, see [docs/OIDC_SETUP.md](docs/OIDC_SETUP.md)

## 🧹 Cleanup

To destroy all resources:
```bash
./scripts/destroy.sh
```

**Warning**: This will permanently delete:
- All DynamoDB data
- S3 buckets and files
- CloudWatch logs and alarms
- All infrastructure resources

## 📝 Customization

### Change AWS Region
Edit [terraform/variables.tf](terraform/variables.tf):
```hcl
variable "aws_region" {
  default     = "us-west-2"  # Change to your preferred region
}
```

### Adjust Lambda Memory
Edit [terraform/lambda.tf](terraform/lambda.tf):
```hcl
resource "aws_lambda_function" "api_handler" {
  memory_size   = 256  # Increase for better performance
  timeout       = 60   # Increase for longer operations
}
```

### Add More Lambda Functions
1. Create new Lambda code in `lambda/` directory
2. Add new Lambda resource in `terraform/lambda.tf`
3. Configure API Gateway routes as needed

### Enable Remote State Backend
After first deployment:
1. Get S3 bucket name from outputs
2. Uncomment backend configuration in [terraform/main.tf](terraform/main.tf)
3. Update bucket name with your AWS account ID
4. Run `terraform init -migrate-state`

## 🎓 Learning Outcomes

This project demonstrates proficiency in:

- ☑️ **AWS Cloud Architecture**: Designing scalable serverless solutions
- ☑️ **Infrastructure as Code**: Managing infrastructure with Terraform
- ☑️ **DevOps Automation**: Scripting deployment pipelines
- ☑️ **API Development**: Building RESTful APIs with Lambda
- ☑️ **Monitoring & Observability**: CloudWatch dashboards and alerting
- ☑️ **Cost Optimization**: Maximizing Free Tier resources
- ☑️ **Security**: Implementing cloud security best practices
- ☑️ **Documentation**: Clear, comprehensive project documentation

## 🐛 Troubleshooting

### Terraform apply fails
- Ensure AWS credentials are configured: `aws sts get-caller-identity`
- Check if you have required AWS permissions
- Verify no resource naming conflicts exist

### CloudFront distribution takes long to deploy
- CloudFront distributions take 1-3 minutes to deploy (normal)
- Use S3 website endpoint during development for faster testing

### Lambda function errors
- Check CloudWatch Logs: `/aws/lambda/aws-infra-automation-api-handler`
- Verify DynamoDB table name in environment variables
- Ensure IAM role has DynamoDB permissions

### API Gateway returns 502/504
- Check Lambda function logs for errors
- Verify Lambda timeout is sufficient
- Check if Lambda is in a VPC subnet with internet access

## 📚 Additional Resources

- [AWS Free Tier Details](https://aws.amazon.com/free/)
- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [DynamoDB Best Practices](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html)

## 🤝 Contributing

This is a portfolio project, but suggestions and improvements are welcome!

## 📄 License

MIT License - feel free to use this for your own portfolio projects.

## 👤 Author

**Viren Patel**
- LinkedIn: (www.linkedin.com/in/viren-patel1993)
- Portfolio: (https://d300eus0ocvg7w.cloudfront.net/)
- GitHub: (https://github.com/Viren1993-web/aws-infra-automation)

---

⭐ **Star this repo if you find it helpful for your learning journey!**
