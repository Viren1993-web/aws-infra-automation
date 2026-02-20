# AWS Infrastructure Automation — Architecture

> A visual guide to every component and how they connect. No code reading required.

---

## High-Level Architecture

```mermaid
flowchart TB
    User((User / Browser))

    subgraph CF["CloudFront CDN"]
        CDN[CloudFront Distribution<br/>HTTPS · PriceClass_100<br/>NA + EU edge locations]
    end

    subgraph Static["Static Website"]
        S3W[S3 Bucket<br/>index.html · error.html<br/>Public read · OAC]
    end

    subgraph API["API Layer"]
        APIGW[API Gateway HTTP API<br/>CORS enabled<br/>Auto-deploy stage]
    end

    subgraph Compute["Compute"]
        Lambda[Lambda Function<br/>Python 3.11 · 128 MB · 30s<br/>CRUD handler]
    end

    subgraph Data["Data Store"]
        DDB[DynamoDB Table<br/>Partition key: id · GSI: StatusIndex<br/>Auto-scaling 1–10 RCU/WCU<br/>Encryption · PITR]
    end

    subgraph Net["VPC  10.0.0.0/16"]
        Sub1[Public Subnet 1<br/>10.0.1.0/24 · AZ-a]
        Sub2[Public Subnet 2<br/>10.0.2.0/24 · AZ-b]
        IGW[Internet Gateway]
        SG[Security Group<br/>Egress-only]
    end

    subgraph Monitor["Monitoring & Alerts"]
        CW[CloudWatch<br/>Dashboard · 6 Alarms<br/>7-day log retention]
        SNS[SNS Topic<br/>Email notifications]
    end

    subgraph CICD["CI/CD Pipeline"]
        GHA[GitHub Actions<br/>CI: validate · lint · scan<br/>CD: apply · upload · invalidate]
        OIDC[OIDC Provider<br/>Temporary STS tokens]
    end

    subgraph State["Terraform State"]
        S3T[S3 Bucket<br/>Versioned · AES-256 encrypted]
    end

    User -->|HTTPS| CDN
    CDN -->|Static files| S3W
    CDN -->|Custom error 404| S3W
    User -->|REST API| APIGW
    APIGW -->|AWS_PROXY| Lambda
    Lambda -->|Read/Write| DDB
    Lambda -.->|Runs in| Sub1 & Sub2
    Sub1 & Sub2 -->|Route via| IGW
    SG -.->|Attached to| Lambda
    Lambda -->|Logs| CW
    APIGW -->|Access logs| CW
    CW -->|Alarm triggers| SNS
    SNS -->|Email| User
    GHA -->|OIDC auth| OIDC
    OIDC -->|STS AssumeRole| Lambda & S3W & DDB & CDN
    GHA -->|terraform apply| S3T
```

---

## Request Flow — API Call

```mermaid
sequenceDiagram
    actor U as User
    participant CF as CloudFront
    participant AG as API Gateway
    participant LM as Lambda
    participant DB as DynamoDB
    participant CW as CloudWatch

    U->>AG: HTTPS request (GET/POST/PUT/DELETE)
    AG->>LM: AWS_PROXY invocation
    LM->>DB: boto3 read/write
    DB-->>LM: Response
    LM-->>AG: JSON response + status code
    AG-->>U: HTTP response
    LM->>CW: Logs (auto)
    AG->>CW: Access logs (auto)
    CW-->>CW: Evaluate alarm thresholds
    CW->>CW: Trigger SNS if breached
```

---

## CI/CD Pipeline

```mermaid
flowchart LR
    subgraph PR["Pull Request"]
        A[Push / PR] --> B[terraform fmt]
        B --> C[Python lint]
        C --> D[Security scan<br/>GitLeaks · tfsec]
        D --> E[terraform plan<br/>→ PR comment]
    end

    subgraph Deploy["Merge to main"]
        F[terraform apply] --> G[Upload website → S3]
        G --> H[Invalidate CloudFront cache]
        H --> I[Deployment summary]
    end

    PR -->|Merge| Deploy

    subgraph Auth["Authentication"]
        OIDC[GitHub OIDC token] -->|1h temp creds| STS[AWS STS]
        STS --> Role[DeployerAccess-Github<br/>Custom inline policy]
    end

    Deploy -.->|Uses| Auth
```

---

## Networking

```mermaid
flowchart TB
    subgraph VPC["VPC  10.0.0.0/16"]
        subgraph AZa["Availability Zone a"]
            Pub1[Public Subnet<br/>10.0.1.0/24]
        end
        subgraph AZb["Availability Zone b"]
            Pub2[Public Subnet<br/>10.0.2.0/24]
        end
        RT[Route Table<br/>0.0.0.0/0 → IGW]
        SG[Security Group<br/>All egress · No ingress]
    end
    IGW[Internet Gateway]
    Pub1 & Pub2 --> RT --> IGW
    SG -.-> Pub1 & Pub2
    Lambda[Lambda ENIs] -.->|Placed in| Pub1 & Pub2
```

---

## Monitoring & Alerting

```mermaid
flowchart LR
    subgraph Sources
        LM[Lambda]
        AG[API Gateway]
        DB[DynamoDB]
    end

    subgraph CloudWatch
        Logs[Log Groups<br/>7-day retention]
        Dash[Dashboard<br/>Lambda · API · DynamoDB metrics]
        Alarms[6 Alarms]
    end

    subgraph Alerts
        SNS[SNS Topic]
        Email[Email Notification]
    end

    LM & AG --> Logs
    LM & AG & DB --> Dash
    Dash --> Alarms
    Alarms -->|Threshold breached| SNS --> Email
```

| Alarm | Metric | Threshold |
|-------|--------|-----------|
| Lambda Errors | `Errors` sum / 5 min | > 5 |
| Lambda Duration | `Duration` avg / 5 min | > 25 s |
| Lambda Throttles | `Throttles` sum / 5 min | > 10 |
| API 5XX Errors | `5XXError` sum / 5 min | > 10 |
| DynamoDB Read | `ConsumedReadCapacityUnits` / 5 min | > 80% |
| DynamoDB Write | `ConsumedWriteCapacityUnits` / 5 min | > 80% |

---

## Security Layers

```mermaid
flowchart TB
    subgraph External
        HTTPS[HTTPS Only<br/>CloudFront redirect]
        CORS[CORS<br/>API Gateway config]
        OAC[Origin Access Control<br/>S3 ↔ CloudFront]
    end

    subgraph Identity
        OIDC[OIDC<br/>No stored secrets]
        IAMRole[Lambda Execution Role<br/>Least-privilege]
        DeployRole[DeployerAccess-Github<br/>Custom inline policy]
    end

    subgraph DataProtection
        S3Enc[S3 State Bucket<br/>AES-256 · Versioned]
        DDBEnc[DynamoDB<br/>SSE · PITR]
        VPCIso[VPC Isolation<br/>Security group egress-only]
    end
```

---

## Terraform File Map

| File | Creates |
|------|---------|
| `main.tf` | Provider config, S3 remote backend |
| `variables.tf` | Input variables (region, project name, email) |
| `outputs.tf` | URLs, ARNs, resource IDs |
| `vpc.tf` | VPC, 2 public subnets, IGW, route table, security group |
| `s3.tf` | Website bucket + policy, Terraform state bucket (versioned, encrypted) |
| `lambda.tf` | Lambda function, IAM role/policy, API Gateway HTTP API, routes, stage |
| `dynamodb.tf` | DynamoDB table, GSI, auto-scaling targets + policies |
| `cloudfront.tf` | CloudFront distribution, OAC, S3 bucket policy update |
| `monitoring.tf` | SNS topic, 6 CloudWatch alarms, dashboard |

---

## Cost — $0/month

| Service | Free Tier Limit | Project Usage |
|---------|----------------|---------------|
| Lambda | 1M req + 400K GB-s | Minimal |
| DynamoDB | 25 GB, 25 RCU/WCU | 5 RCU/WCU, auto-scale to 10 |
| S3 | 5 GB, 20K GET | 2 HTML files |
| CloudFront | 1 TB transfer, 10M req | Portfolio traffic |
| API Gateway | 1M calls | Demo usage |
| CloudWatch | 10 alarms, 5 GB logs | 6 alarms, 7-day retention |
| SNS | 1M publishes | Alert emails only |
| VPC | Free (no NAT) | 2 public subnets |
