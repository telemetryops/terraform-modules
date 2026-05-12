output "lambda_private_security_group_id" {
  description = "Security group ID for private Lambda workloads."
  value       = aws_security_group.lambda_private.id
}

output "vpc_endpoint_security_group_id" {
  description = "Security group ID for interface VPC endpoints."
  value       = aws_security_group.vpc_endpoint.id
}

output "data_store_security_group_id" {
  description = "Security group ID for private data stores."
  value       = aws_security_group.data_store.id
}

output "private_workload_network_acl_id" {
  description = "Network ACL ID associated with private workload subnets."
  value       = aws_network_acl.private_workload.id
}

output "public_edge_network_acl_id" {
  description = "Optional public edge network ACL ID, or null when no public subnets are configured."
  value       = length(aws_network_acl.public_edge) > 0 ? aws_network_acl.public_edge[0].id : null
}
