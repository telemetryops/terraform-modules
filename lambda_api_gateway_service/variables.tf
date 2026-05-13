variable "function_name" {
  description = "Name of the Rust Lambda function."
  type        = string
}

variable "memory_size" {
  description = "Amount of memory in MB your Lambda function can use at runtime."
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Amount of time your Lambda function has to run in seconds."
  type        = number
  default     = 30
}

variable "environment_variables" {
  description = "Map of environment variables to set for the Lambda function."
  type        = map(string)
  default     = {}
}

variable "vpc_config" {
  description = "Optional VPC configuration for private Lambda networking."
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null

  validation {
    condition = var.vpc_config == null || (
      length(var.vpc_config.subnet_ids) > 0 &&
      length(var.vpc_config.security_group_ids) > 0
    )
    error_message = "vpc_config must include at least one subnet ID and one security group ID."
  }
}

variable "cloudwatch_log_kms_key_arn" {
  description = "Optional KMS key ARN used to encrypt the Lambda CloudWatch Logs log group."
  type        = string
  default     = null
}

variable "cloudwatch_log_retention_days" {
  description = "CloudWatch Logs retention period for the Lambda log group."
  type        = number
  default     = 90
}

variable "cross_account_role_arns" {
  description = "List of cross-account IAM role ARNs this Lambda can assume."
  type        = list(string)
  default     = []
}

variable "additional_permissions" {
  description = "List of additional IAM permissions to attach to the Lambda role."
  type = list(object({
    name      = string
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}

variable "rest_api_id" {
  description = "The ID of the API Gateway REST API."
  type        = string
}

variable "root_resource_id" {
  description = "The root resource ID of the API Gateway REST API."
  type        = string
}

variable "rest_api_execution_arn" {
  description = "The API Gateway REST API execution ARN, used to grant Lambda invoke permissions."
  type        = string
}

variable "endpoints" {
  description = "Map of endpoint paths to API Gateway method and CORS configuration. Do not include any base path mapping prefix."
  type = map(object({
    authorizer_id      = optional(string)
    methods            = list(string)
    cors_allow_methods = string
  }))

  validation {
    condition     = length(var.endpoints) > 0
    error_message = "At least one endpoint must be configured."
  }

  validation {
    condition = alltrue([
      for endpoint_path, config in var.endpoints :
      endpoint_path == trim(endpoint_path, "/") &&
      length(endpoint_path) > 0 &&
      length(config.methods) > 0
    ])
    error_message = "Endpoint paths must be non-empty relative paths without leading/trailing slashes, and each endpoint must define at least one method."
  }
}

variable "cors_allow_origin" {
  description = "CORS Access-Control-Allow-Origin header value."
  type        = string
  default     = "'*'"
}

variable "cors_allow_headers" {
  description = "CORS Access-Control-Allow-Headers header value."
  type        = string
  default     = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
}

variable "authorizer_id" {
  description = "Optional default API Gateway custom authorizer ID. Endpoint authorizer_id values override this."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
