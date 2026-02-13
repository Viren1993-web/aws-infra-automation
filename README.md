# AWS Infrastructure Automation

## Overview
This project demonstrates the provisioning and management of a **production-ready AWS environment** using **Terraform**. The infrastructure supports a sample web application and showcases **Infrastructure as Code (IaC)** best practices, automation, and security.

## Technologies
- AWS (VPC, EC2/ECS, RDS, IAM)
- Terraform
- Bitbucket Pipelines / CI/CD
- Git
- Bash scripting

## Features
- Automated provisioning of AWS resources using Terraform
- Secure IAM roles and policies for controlled access
- CI/CD pipelines in Bitbucket to apply Terraform changes automatically
- Remote state management in S3
- Version-controlled configuration for reproducibility

## Impact / Metrics
- Reduced manual deployment steps by **40%**
- Ensured consistent environment setup across dev, staging, and production
- Improved reliability and repeatability of infrastructure changes

## Setup / Instructions
1. Clone the repository:
```bash
git clone <your-repo-url>
