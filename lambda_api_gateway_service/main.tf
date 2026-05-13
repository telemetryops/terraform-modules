locals {
  normalized_endpoints = {
    for endpoint_path, config in var.endpoints : endpoint_path => {
      lambda_invoke_arn  = module.lambda.invoke_arn
      authorizer_id      = config.authorizer_id
      methods            = config.methods
      cors_allow_methods = config.cors_allow_methods
    }
  }

  endpoint_methods = merge([
    for endpoint_path, config in var.endpoints : {
      for method in config.methods :
      "${endpoint_path}::${method}" => {
        path   = endpoint_path
        method = method
      }
    }
  ]...)

  api_gateway_source_arns = {
    for key, config in local.endpoint_methods :
    key => "${var.rest_api_execution_arn}/*/${config.method}/${config.path}"
  }
}

module "lambda" {
  source = "../lambda_rust_function"

  function_name                 = var.function_name
  memory_size                   = var.memory_size
  timeout                       = var.timeout
  environment_variables         = var.environment_variables
  vpc_config                    = var.vpc_config
  cloudwatch_log_kms_key_arn    = var.cloudwatch_log_kms_key_arn
  cloudwatch_log_retention_days = var.cloudwatch_log_retention_days
  cross_account_role_arns       = var.cross_account_role_arns
  additional_permissions        = var.additional_permissions
  tags                          = var.tags
}

module "api_gateway_endpoints" {
  source = "../api_gateway_endpoints"

  rest_api_id        = var.rest_api_id
  root_resource_id   = var.root_resource_id
  lambda_invoke_arn  = module.lambda.invoke_arn
  endpoints          = local.normalized_endpoints
  cors_allow_origin  = var.cors_allow_origin
  cors_allow_headers = var.cors_allow_headers
  authorizer_id      = var.authorizer_id
}

resource "aws_lambda_permission" "api_gateway_invoke" {
  for_each = local.api_gateway_source_arns

  statement_id  = "AllowAPIGateway${substr(sha1(each.key), 0, 16)}"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = each.value
}
