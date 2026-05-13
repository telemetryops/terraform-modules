variable "name_prefix" {
  description = "Resource name prefix, typically <org>-<environment>."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,62}[a-z0-9])?$", var.name_prefix))
    error_message = "name_prefix must be a lowercase DNS-label style value."
  }
}

variable "vpc_cidr_block" {
  description = "Primary IPv4 CIDR block for the VPC."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr_block))
    error_message = "vpc_cidr_block must be a valid IPv4 CIDR block."
  }
}

variable "az_count" {
  description = "Number of Availability Zones to use."
  type        = number

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 6
    error_message = "az_count must be between 2 and 6."
  }
}

variable "availability_zones" {
  description = "Optional explicit Availability Zone names. When set, provide enough names for all public/private subnet CIDR blocks."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.availability_zones) == 0 || length(var.availability_zones) >= 2
    error_message = "availability_zones must be empty or contain at least two entries."
  }
}

variable "public_subnet_cidr_blocks" {
  description = "CIDR blocks for public subnets."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidr_blocks) > 0
    error_message = "public_subnet_cidr_blocks must contain at least one CIDR block."
  }

  validation {
    condition     = alltrue([for cidr in var.public_subnet_cidr_blocks : can(cidrnetmask(cidr))])
    error_message = "public_subnet_cidr_blocks must contain valid IPv4 CIDR blocks."
  }
}

variable "private_subnet_cidr_blocks" {
  description = "CIDR blocks for private Lambda/data-plane subnets."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidr_blocks) > 0
    error_message = "private_subnet_cidr_blocks must contain at least one CIDR block."
  }

  validation {
    condition     = alltrue([for cidr in var.private_subnet_cidr_blocks : can(cidrnetmask(cidr))])
    error_message = "private_subnet_cidr_blocks must contain valid IPv4 CIDR blocks."
  }
}

variable "enable_nat_gateway" {
  description = "Whether to create a single NAT gateway in the first public subnet for approved HTTPS egress."
  type        = bool
  default     = true
}

variable "nat_https_egress_cidr_blocks" {
  description = "CIDR blocks private Lambda workloads may reach over HTTPS through NAT."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.nat_https_egress_cidr_blocks : can(cidrnetmask(cidr))])
    error_message = "nat_https_egress_cidr_blocks must contain valid IPv4 CIDR blocks."
  }
}

variable "enable_iot_endpoints" {
  description = "Whether to create IoT Core data and credentials interface VPC endpoints."
  type        = bool
  default     = true
}

variable "enable_timestream_endpoints" {
  description = "Whether to create Timestream write and query interface VPC endpoints."
  type        = bool
  default     = true
}

variable "interface_endpoint_private_dns_enabled" {
  description = "Whether interface endpoints should enable private DNS."
  type        = bool
  default     = true
}

variable "additional_interface_endpoints" {
  description = "Additional interface endpoint service names keyed by logical endpoint name."
  type = map(object({
    service_name = string
  }))
  default = {}
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
