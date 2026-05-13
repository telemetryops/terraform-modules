# VPC Network Module

Creates a production VPC foundation for TelemetryOps service workloads:

- One VPC with DNS hostnames/support enabled.
- Public subnets, public route table, internet gateway, and optional single NAT
  gateway.
- Private subnets and a private route table for Lambda/data-plane workloads.
- Lambda, IoT endpoint, and Timestream endpoint security groups.
- Interface endpoints for IoT Core data, IoT Core credentials, Timestream write,
  and Timestream query.

```hcl
module "vpc_network" {
  source = "git::https://github.com/telemetryops/terraform-modules.git//vpc_network?ref=main"

  name_prefix    = "telemetryops-prod"
  vpc_cidr_block = "10.40.0.0/16"
  az_count       = 2

  public_subnet_cidr_blocks = [
    "10.40.0.0/24",
    "10.40.1.0/24",
  ]

  private_subnet_cidr_blocks = [
    "10.40.10.0/24",
    "10.40.11.0/24",
  ]

  nat_https_egress_cidr_blocks = [
    "0.0.0.0/0"
  ]

  tags = {
    Project     = "telemetryops"
    Environment = "prod"
  }
}
```

Use `lambda_security_group_id` with the Lambda modules' `vpc_config` input and
`private_subnet_ids` as the Lambda subnet set.
