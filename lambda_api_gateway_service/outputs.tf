output "function_name" {
  description = "Name of the Lambda function."
  value       = module.lambda.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function."
  value       = module.lambda.function_arn
}

output "invoke_arn" {
  description = "Invoke ARN of the Lambda function."
  value       = module.lambda.invoke_arn
}

output "role_arn" {
  description = "ARN of the IAM role used by the Lambda function."
  value       = module.lambda.role_arn
}

output "role_name" {
  description = "Name of the IAM role used by the Lambda function."
  value       = module.lambda.role_name
}

output "log_group_name" {
  description = "Name of the CloudWatch Logs log group for the Lambda function."
  value       = module.lambda.log_group_name
}

output "resource_ids" {
  description = "Map of endpoint paths to their API Gateway resource IDs."
  value       = module.api_gateway_endpoints.resource_ids
}

output "integration_ids" {
  description = "Map of endpoint::method to their integration IDs."
  value       = module.api_gateway_endpoints.integration_ids
}

output "options_integration_ids" {
  description = "Map of endpoint paths to OPTIONS integration response IDs."
  value       = module.api_gateway_endpoints.options_integration_ids
}

output "lambda_permission_statement_ids" {
  description = "Map of endpoint::method to Lambda API Gateway permission statement IDs."
  value       = { for key, permission in aws_lambda_permission.api_gateway_invoke : key => permission.statement_id }
}
