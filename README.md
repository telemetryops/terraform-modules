# TelemetryOps Terraform Modules

Reusable Terraform modules for TelemetryOps production infrastructure.

## Modules

- `lambda_container_function` - Python Lambda with Docker + ECR.
- `lambda_rust_function` - Rust Lambda with cargo-lambda.
- `lambda_api_gateway_service` - Rust Lambda plus API Gateway endpoint wiring and invoke permissions.
- `api_gateway_endpoints` - API Gateway resource/method/integration wiring.
- `network_security` - VPC security groups and NACLs for private Lambda workloads, interface endpoints, and private data stores.
