variable "rest_api_id" {
  description = "The ID of the API Gateway REST API"
  type        = string
}

variable "root_resource_id" {
  description = "The root resource ID of the API Gateway REST API"
  type        = string
}

variable "lambda_invoke_arn" {
  description = "The invoke ARN of the Lambda function to integrate with (used if lambda_invoke_arn not specified per-endpoint)"
  type        = string
  default     = ""
}

variable "endpoints" {
  description = "Map of endpoint paths to their configuration"
  type = map(object({
    lambda_invoke_arn  = optional(string)
    authorizer_id      = optional(string)
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

variable "authorizer_id" {
  description = "Optional default API Gateway custom authorizer ID. Endpoints can override this with their own authorizer_id value. When no authorizer is set, methods are unprotected (authorization=NONE)."
  type        = string
  default     = null
}
