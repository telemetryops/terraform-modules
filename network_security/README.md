# Network Security Module

Reusable Terraform for TelemetryOps VPC network controls.

The module creates:

- A private Lambda security group with no ingress and only explicit HTTPS egress.
- An interface VPC endpoint security group that accepts HTTPS only from private Lambdas.
- A private data-store security group that accepts only configured TCP ports from private Lambdas.
- A private workload subnet NACL allowing VPC-local traffic and explicit HTTPS egress ranges.
- An optional public edge subnet NACL that rejects `0.0.0.0/0` ingress and should only be used for CloudFront-facing origins or similar edge-only resources.

Example:

```hcl
module "network_security" {
  source = "git::https://github.com/telemetryops/terraform-modules.git//network_security?ref=main"

  name_prefix        = "telemetryops-prod"
  vpc_id             = aws_vpc.main.id
  vpc_cidr_block     = aws_vpc.main.cidr_block
  private_subnet_ids = aws_subnet.private[*].id

  https_egress_cidr_blocks = [
    aws_vpc.main.cidr_block
  ]

  data_store_ports = [
    5432,
    6379
  ]

  tags = {
    Project     = "telemetryops"
    Environment = "prod"
  }
}
```

Do not attach public workloads directly to this module. TelemetryOps public traffic should enter through managed edge services such as CloudFront or API Gateway.
