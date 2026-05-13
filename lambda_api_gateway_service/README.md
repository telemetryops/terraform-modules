# Lambda API Gateway Service

Composes a Rust Lambda function, API Gateway REST resources/methods, CORS
preflight handling, and Lambda invoke permissions into one service module.

Endpoint paths are relative to the API root after any base path mapping is
stripped. For example, if the API base path is `admin`, configure `users`, not
`admin/users`.

```hcl
module "organizations_api" {
  source = "../terraform-modules/lambda_api_gateway_service"

  function_name          = "telemetryops-prod-admin-lambda"
  rest_api_id           = aws_api_gateway_rest_api.api.id
  root_resource_id      = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_execution_arn = aws_api_gateway_rest_api.api.execution_arn

  endpoints = {
    "organizations" = {
      methods            = ["GET", "POST"]
      cors_allow_methods = "'GET,POST,OPTIONS'"
    }
    "organizations/{org_id}" = {
      methods            = ["GET", "PATCH", "DELETE"]
      cors_allow_methods = "'GET,PATCH,DELETE,OPTIONS'"
    }
  }

  environment_variables = {
    ORGANIZATIONS_TABLE = aws_dynamodb_table.organizations.name
  }

  additional_permissions = [
    {
      name      = "organizations"
      actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:DeleteItem"]
      resources = [aws_dynamodb_table.organizations.arn]
    }
  ]

  tags = local.common_tags
}
```
