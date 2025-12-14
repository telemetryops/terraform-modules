# IMPORTANT: Base path mappings STRIP the base path before routing.
#
# Correct: base_path="admin" + resource="/users" = api.com/admin/users ✅
# Wrong:   base_path="admin" + resource="/admin/users" = api.com/admin/admin/users ❌
#
# DO NOT include the base path in your endpoint paths.

locals {
  # Extract all unique path segments from all endpoints
  all_path_segments = flatten([
    for endpoint_path, config in var.endpoints : [
      for i in range(1, length(split("/", endpoint_path)) + 1) :
        join("/", slice(split("/", endpoint_path), 0, i))
    ]
  ])

  unique_path_segments = toset(local.all_path_segments)

  # Find maximum depth needed
  max_depth = max([for seg in local.unique_path_segments : length(split("/", seg))]...)

  # Create a map of path segments grouped by depth level
  segments_by_level = {
    for level in range(1, local.max_depth + 1) : level => {
      for segment in local.unique_path_segments :
        segment => {
          parent = length(split("/", segment)) == 1 ? null : join("/", slice(split("/", segment), 0, length(split("/", segment)) - 1))
          part   = element(split("/", segment), length(split("/", segment)) - 1)
        }
      if length(split("/", segment)) == level
    }
  }
}

# Create resources level by level to avoid cycles
# Level 1
resource "aws_api_gateway_resource" "level_1" {
  for_each    = local.max_depth >= 1 ? local.segments_by_level[1] : {}
  rest_api_id = var.rest_api_id
  parent_id   = var.root_resource_id
  path_part   = each.value.part
}

# Level 2
resource "aws_api_gateway_resource" "level_2" {
  for_each    = local.max_depth >= 2 ? local.segments_by_level[2] : {}
  rest_api_id = var.rest_api_id
  parent_id   = aws_api_gateway_resource.level_1[each.value.parent].id
  path_part   = each.value.part
}

# Level 3
resource "aws_api_gateway_resource" "level_3" {
  for_each    = local.max_depth >= 3 ? local.segments_by_level[3] : {}
  rest_api_id = var.rest_api_id
  parent_id   = aws_api_gateway_resource.level_2[each.value.parent].id
  path_part   = each.value.part
}

# Level 4
resource "aws_api_gateway_resource" "level_4" {
  for_each    = local.max_depth >= 4 ? local.segments_by_level[4] : {}
  rest_api_id = var.rest_api_id
  parent_id   = aws_api_gateway_resource.level_3[each.value.parent].id
  path_part   = each.value.part
}

# Level 5
resource "aws_api_gateway_resource" "level_5" {
  for_each    = local.max_depth >= 5 ? local.segments_by_level[5] : {}
  rest_api_id = var.rest_api_id
  parent_id   = aws_api_gateway_resource.level_4[each.value.parent].id
  path_part   = each.value.part
}

# Level 6
resource "aws_api_gateway_resource" "level_6" {
  for_each    = local.max_depth >= 6 ? local.segments_by_level[6] : {}
  rest_api_id = var.rest_api_id
  parent_id   = aws_api_gateway_resource.level_5[each.value.parent].id
  path_part   = each.value.part
}

# Merge all levels into one map
locals {
  path_resource_ids = merge(
    { for k, v in aws_api_gateway_resource.level_1 : k => v.id },
    { for k, v in aws_api_gateway_resource.level_2 : k => v.id },
    { for k, v in aws_api_gateway_resource.level_3 : k => v.id },
    { for k, v in aws_api_gateway_resource.level_4 : k => v.id },
    { for k, v in aws_api_gateway_resource.level_5 : k => v.id },
    { for k, v in aws_api_gateway_resource.level_6 : k => v.id }
  )
}

# Create POST/GET/etc methods for each endpoint
resource "aws_api_gateway_method" "endpoint_methods" {
  for_each = merge([
    for endpoint_path, config in var.endpoints : {
      for method in config.methods :
        "${endpoint_path}::${method}" => {
          path   = endpoint_path
          method = method
        }
    }
  ]...)

  rest_api_id   = var.rest_api_id
  resource_id   = local.path_resource_ids[each.value.path]
  http_method   = each.value.method
  authorization = "NONE"
}

# Create OPTIONS methods for CORS on each endpoint
resource "aws_api_gateway_method" "endpoint_options" {
  for_each = var.endpoints

  rest_api_id   = var.rest_api_id
  resource_id   = local.path_resource_ids[each.key]
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Create Lambda integrations for each method
resource "aws_api_gateway_integration" "endpoint_lambda" {
  for_each = merge([
    for endpoint_path, config in var.endpoints : {
      for method in config.methods :
        "${endpoint_path}::${method}" => {
          path   = endpoint_path
          method = method
        }
    }
  ]...)

  rest_api_id = var.rest_api_id
  resource_id = local.path_resource_ids[each.value.path]
  http_method = aws_api_gateway_method.endpoint_methods[each.key].http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = var.lambda_invoke_arn
}

# Create CORS OPTIONS mock integrations
resource "aws_api_gateway_integration" "endpoint_options" {
  for_each = var.endpoints

  rest_api_id = var.rest_api_id
  resource_id = local.path_resource_ids[each.key]
  http_method = aws_api_gateway_method.endpoint_options[each.key].http_method

  type = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# Create CORS OPTIONS method responses
resource "aws_api_gateway_method_response" "endpoint_options" {
  for_each = var.endpoints

  rest_api_id = var.rest_api_id
  resource_id = local.path_resource_ids[each.key]
  http_method = aws_api_gateway_method.endpoint_options[each.key].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# Create CORS OPTIONS integration responses
resource "aws_api_gateway_integration_response" "endpoint_options" {
  for_each = var.endpoints

  rest_api_id = var.rest_api_id
  resource_id = local.path_resource_ids[each.key]
  http_method = aws_api_gateway_method.endpoint_options[each.key].http_method
  status_code = aws_api_gateway_method_response.endpoint_options[each.key].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = var.cors_allow_headers
    "method.response.header.Access-Control-Allow-Methods" = each.value.cors_allow_methods
    "method.response.header.Access-Control-Allow-Origin"  = var.cors_allow_origin
  }

  depends_on = [aws_api_gateway_integration.endpoint_options]
}
