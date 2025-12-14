variable "rest_api_id" {
  description = "The ID of the API Gateway REST API"
  type        = string
}

variable "root_resource_id" {
  description = "The root resource ID of the API Gateway REST API"
  type        = string
}

variable "lambda_invoke_arn" {
  description = "The invoke ARN of the Lambda function to integrate with"
  type        = string
}

variable "endpoints" {
  description = "Map of endpoint paths to their configuration"
  type = map(object({
    methods            = list(string)
    cors_allow_methods = string
  }))
}

variable "cors_allow_origin" {
  description = "CORS Access-Control-Allow-Origin header value"
  type        = string
  default     = "'*'"
}

variable "cors_allow_headers" {
  description = "CORS Access-Control-Allow-Headers header value"
  type        = string
  default     = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
}
