# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Initial Project Setup (v0.1.0)**
  - Created initial, empty modules for `ecs-service`, `lambda-service`, `vpc`, `ecr`, `rds`, `documentdb`, `elasticache`, `msk`, `opensearch`, and `alb`.
- **SSM & Logging Integration (v0.2.0)**
  - Added `cloudwatch-logs` module for centralized log group creation and subscription to a log forwarder.
  - Modified `ecs-service` and `lambda-service` modules to automatically use the `cloudwatch-logs` module.
  - Modified `ecs-service` and `lambda-service` to accept a list of IAM policy ARNs (`task_policy_arns` and `execution_policy_arns`) for better security and flexibility.
- **Module Implementation (v0.3.0)**
  - Implemented basic, cost-effective configurations for `alb`, `documentdb`, `elasticache`, `rds`, `vpc`, and `opensearch` modules.
  - `vpc` module now creates a VPC with public/private subnets and a single NAT Gateway for cost savings.
  - `documentdb`, `rds`, and `elasticache` modules are configured to use small, single-instance setups suitable for development.
  - `opensearch` module is configured for a single-node `t3.small.search` instance.

### Changed
- `ecs-service` module no longer creates its own `aws_cloudwatch_log_group`. This responsibility is now delegated to the `cloudwatch-logs` module it invokes.
- `lambda-service` module now depends on the `cloudwatch-logs` module to ensure the log group and subscription filter are created before the Lambda function is provisioned.

### Removed
- `msk` module was removed as the project will use a self-managed Kafka cluster on EC2 for cost reasons.
