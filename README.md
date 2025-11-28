# AWS Data Pipeline Demo

This repository simulates an industry-style data engineering project on AWS.

## Business Use Case

A daily CSV file with sales data lands in an S3 raw bucket.  
An event-driven Lambda function is triggered, performs basic transformations, and writes the cleaned file to a processed S3 bucket.

The focus of this project is to practice:

- Terraform-based infrastructure as code
- IAM roles, groups, and policies
- Event-driven architecture using S3 and EventBridge
- Lambda development and packaging with Docker
- CI/CD using GitHub Actions, feature branches, and approvals
- Secrets management using AWS Secrets Manager

## Tech Stack

- AWS: S3, Lambda, IAM, EventBridge, Secrets Manager
- Terraform for infrastructure
- Python for application logic
- Docker for building Lambda artifacts
- GitHub Actions for CI/CD
- Git feature branches and PR-based workflows

## Repository Structure

See `docs/architecture.md` for a detailed overview.

## Getting Started

1. Install Python, Terraform, Docker, AWS CLI, and VS Code.
2. Configure an AWS profile with access to your dev account.
3. Follow `docs/onboarding.md` to set up your local environment.
