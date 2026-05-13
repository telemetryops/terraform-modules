variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "memory_size" {
  description = "Amount of memory in MB your Lambda function can use at runtime"
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Amount of time your Lambda function has to run in seconds"
  type        = number
  default     = 30
}

variable "environment_variables" {
  description = "Map of environment variables to set for the Lambda function"
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
  description = "List of cross-account IAM role ARNs this Lambda can assume"
  type        = list(string)
  default     = []
}

variable "additional_permissions" {
  description = "List of additional IAM permissions to attach to the Lambda role"
  type = list(object({
    name      = string
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
