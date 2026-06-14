# SSP Infrastructure Modules (terraform-infra-child)

This repository serves as the central library of reusable Terraform child modules for the Smart Shop Platform (SSP). 

By extracting infrastructure primitives (like a standard ECS service or a standard Lambda function) into parameterized modules, we achieve:
- **Consistency:** Every microservice is deployed with the exact same security groups, IAM role structures, and logging configurations.
- **Maintainability:** If we need to update the default log retention period or add a new security sidecar, we update the module here once, and all services inherit the change on their next deployment.
- **Separation of Concerns:** Application developers can deploy their services using simple Terraform code without needing to be experts in AWS networking or IAM.

## Available Modules

### Compute & Application
- **`ecs-service`**: Provisions an AWS ECS Fargate service, task definition, and execution role. Automatically integrates with the `cloudwatch-logs` module for centralized log forwarding.
- **`lambda-service`**: Provisions an AWS Lambda function packaged as a container image. Manages execution roles and automatically integrates with the `cloudwatch-logs` module.

### Databases & Storage
- **`rds`**: Provisions an Amazon RDS PostgreSQL instance within private subnets.
- **`documentdb`**: Provisions a cost-effective, single-instance Amazon DocumentDB (MongoDB-compatible) cluster.
- **`elasticache`**: Provisions a minimal Redis cluster using Amazon ElastiCache.
- **`opensearch`**: Provisions an Amazon OpenSearch domain with vector search capabilities.

### Networking & Security
- **`vpc`**: Provisions the foundational network: VPC, Public/Private subnets, Internet Gateway, Route Tables, and a single, cost-optimized NAT Gateway.
- **`alb`**: Provisions a shared Application Load Balancer that routes traffic from the public subnets to the internal ECS services.
- **`ecr`**: Provisions Amazon Elastic Container Registry repositories with image scanning enabled.

### Observability
- **`cloudwatch-logs`**: A centralized module that creates a CloudWatch Log Group for a service and automatically attaches a subscription filter to forward error logs (`ERROR`, `WARNING`, `CRITICAL`, `Exception`, `Traceback`) to the `ssp-log-forwarder` Lambda.

## Usage

These modules are intended to be sourced remotely (e.g., via GitHub) or locally relative to the caller. 

**Example (ECS Service):**
```hcl
module "ecs_service" {
  source = "../../terraform-infra-child/modules/ecs-service"

  service_name        = "ssp-order-service"
  environment         = "dev"
  cluster_id          = "arn:aws:ecs:..."
  vpc_id              = "vpc-123456"
  private_subnets     = ["subnet-abc", "subnet-def"]
  container_image     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/ssp-order-service:latest"
  container_port      = 80
  
  environment_variables = [
    { name = "KAFKA_BROKER_URL", value = "10.0.2.50:9092" }
  ]
}
```

## Versioning

In production, consumers of these modules should always pin to a specific release tag or commit hash (e.g., `?ref=v1.0.0`) to prevent upstream changes from unintentionally breaking existing infrastructure.
