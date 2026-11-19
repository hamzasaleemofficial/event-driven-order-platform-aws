# Event-Driven Order Processing Platform on AWS

A learning project for building a production-oriented,
event-driven order processing platform using AWS, Python,
Terraform, and GitHub Actions.

## Project Objectives

- Accept orders through Amazon API Gateway.
- Process orders asynchronously using AWS Lambda and Amazon SQS.
- Store order information in Amazon DynamoDB.
- Publish order completion events through Amazon SNS.
- Implement retries, idempotency, and dead-letter queue handling.
- Apply least-privilege IAM and encryption best practices.
- Monitor application health using Amazon CloudWatch and AWS X-Ray.
- Manage infrastructure using reusable Terraform modules.
- Store Terraform state remotely in Amazon S3.
- Automate testing and deployment with GitHub Actions and OIDC.

## Architecture

The API Lambda validates incoming requests, creates order
records, and sends processing messages to SQS.

The Worker Lambda consumes messages, processes orders,
updates DynamoDB, and publishes successful completion events
through SNS.

CloudWatch monitors application health and operational failures.

## Repository Structure

- `application/`: Python Lambda applications.
- `terraform/modules/`: Reusable Terraform modules.
- `terraform/environments/`: Environment-specific configuration.
- `.github/workflows/`: CI/CD workflows.
- `tests/`: Integration and load tests.
- `docs/`: Architecture and operational documentation.

## Implementation Status

- [x] Phase 1: Repository setup and project structure
- [ ] Phase 2: Terraform foundation and remote-state bootstrap
- [ ] Phase 3: Reusable Terraform module design
- [ ] Phase 4: KMS, DynamoDB, SQS, DLQ, and SNS
- [ ] Phase 5: Python API Lambda and API Gateway
- [ ] Phase 6: Python Worker Lambda and SQS integration
- [ ] Phase 7: Idempotency, retries, and failure handling
- [ ] Phase 8: IAM, Secrets Manager, and encryption
- [ ] Phase 9: Monitoring, alarms, dashboard, and tracing
- [ ] Phase 10: GitHub OIDC and Terraform CI/CD
- [ ] Phase 11: Application CI/CD
- [ ] Phase 12: Environment deployments
- [ ] Phase 13: Failure testing, load testing, and cost estimation
- [ ] Phase 14: Documentation and operational runbook

## Security Principles

- Use least-privilege IAM permissions.
- Do not commit credentials or secrets.
- Use GitHub OIDC for GitHub Actions authentication.
- Keep development, staging, and production environments separate.
- Protect Terraform state and production deployments.

## Development Status

The repository is being established incrementally.
AWS infrastructure and application code will be added
in subsequent implementation phases.