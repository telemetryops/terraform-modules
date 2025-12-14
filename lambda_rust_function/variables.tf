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
