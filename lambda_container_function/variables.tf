variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository containing the Lambda container image"
  type        = string
}

variable "build_hash" {
  description = "Build hash/tag for the container image"
  type        = string
}

variable "timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 512
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "cross_account_role_arns" {
  description = "List of cross-account IAM role ARNs this Lambda can assume"
  type        = list(string)
  default     = []
}

variable "additional_permissions" {
  description = "List of additional IAM permissions to grant to the Lambda function"
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
