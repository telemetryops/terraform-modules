output "resource_ids" {
  description = "Map of endpoint paths to their API Gateway resource IDs"
  value       = local.path_resource_ids
}

output "integration_ids" {
  description = "Map of endpoint::method to their integration IDs (for deployment dependencies)"
  value       = { for k, v in aws_api_gateway_integration.endpoint_lambda : k => v.id }
}

output "options_integration_ids" {
  description = "Map of endpoint paths to their OPTIONS integration IDs (for deployment dependencies)"
  value       = { for k, v in aws_api_gateway_integration_response.endpoint_options : k => v.id }
}
