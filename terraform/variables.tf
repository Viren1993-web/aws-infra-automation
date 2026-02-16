variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "aws-infra-automation"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "alert_email" {
  description = "Email address for CloudWatch alerts"
  type        = string
  default     = "pviren9@gmail.com"
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access resources"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    CreatedDate = "2026-02-13"
  }
}
