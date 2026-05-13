output "vpc_id" {
  description = "Created VPC ID."
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "Created VPC IPv4 CIDR block."
  value       = aws_vpc.main.cidr_block
}

output "availability_zones" {
  description = "Availability Zones used by the module."
  value       = local.selected_availability_zones
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "public_subnet_ids_by_index" {
  description = "Public subnet IDs keyed by zero-based AZ index."
  value       = { for index, subnet in aws_subnet.public : index => subnet.id }
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "private_subnet_ids_by_index" {
  description = "Private subnet IDs keyed by zero-based AZ index."
  value       = { for index, subnet in aws_subnet.private : index => subnet.id }
}

output "public_route_table_id" {
  description = "Public route table ID, or null when no public subnets are configured."
  value       = length(aws_route_table.public) > 0 ? aws_route_table.public[0].id : null
}

output "private_route_table_id" {
  description = "Private route table ID."
  value       = aws_route_table.private.id
}

output "nat_gateway_id" {
  description = "NAT gateway ID, or null when NAT is disabled."
  value       = length(aws_nat_gateway.main) > 0 ? aws_nat_gateway.main[0].id : null
}

output "lambda_security_group_id" {
  description = "Security group ID for private Lambda workloads."
  value       = aws_security_group.lambda.id
}

output "iot_endpoint_security_group_id" {
  description = "Security group ID for IoT Core interface endpoints."
  value       = aws_security_group.iot_endpoint.id
}

output "timestream_endpoint_security_group_id" {
  description = "Security group ID for Timestream interface endpoints."
  value       = aws_security_group.timestream_endpoint.id
}

output "additional_endpoint_security_group_ids" {
  description = "Additional interface endpoint security group IDs keyed by endpoint name."
  value       = { for name, sg in aws_security_group.additional_endpoint : name => sg.id }
}

output "interface_endpoint_ids" {
  description = "Interface VPC endpoint IDs keyed by logical endpoint name."
  value       = { for name, endpoint in aws_vpc_endpoint.interface : name => endpoint.id }
}
