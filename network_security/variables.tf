variable "name_prefix" {
  description = "Resource name prefix, typically <org>-<environment>."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,62}[a-z0-9])?$", var.name_prefix))
    error_message = "name_prefix must be a lowercase DNS-label style value."
  }
}

variable "vpc_id" {
  description = "VPC ID where private workloads run."
  type        = string

  validation {
    condition     = can(regex("^vpc-[0-9a-f]+$", var.vpc_id))
    error_message = "vpc_id must be an AWS VPC ID."
  }
}

variable "vpc_cidr_block" {
  description = "Primary VPC CIDR block used for private east-west traffic."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr_block))
    error_message = "vpc_cidr_block must be a valid IPv4 CIDR block."
  }
}

variable "private_subnet_ids" {
  description = "Private subnet IDs to associate with the locked-down workload NACL."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) > 0 && alltrue([for subnet_id in var.private_subnet_ids : can(regex("^subnet-[0-9a-f]+$", subnet_id))])
    error_message = "private_subnet_ids must contain at least one AWS subnet ID."
  }
}

variable "public_subnet_ids" {
  description = "Optional public subnet IDs for edge-only resources. Leave empty when using only CloudFront/API Gateway managed edges."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for subnet_id in var.public_subnet_ids : can(regex("^subnet-[0-9a-f]+$", subnet_id))])
    error_message = "public_subnet_ids must contain AWS subnet IDs."
  }
}

variable "https_egress_cidr_blocks" {
  description = "Explicit CIDR blocks that private Lambda workloads may reach over HTTPS. Use VPC endpoint CIDRs or NAT egress ranges; pass an empty list to disable internet HTTPS egress."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.https_egress_cidr_blocks : can(cidrnetmask(cidr))])
    error_message = "https_egress_cidr_blocks must contain valid IPv4 CIDR blocks."
  }
}

variable "data_store_ports" {
  description = "TCP ports that Lambda workloads may use to reach private data stores."
  type        = list(number)
  default     = []

  validation {
    condition     = alltrue([for port in var.data_store_ports : port > 0 && port <= 65535])
    error_message = "data_store_ports must contain valid TCP ports."
  }
}

variable "allowed_public_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to reach public edge subnets on HTTP/HTTPS. This should normally be CloudFront origin-facing ranges or empty."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.allowed_public_ingress_cidr_blocks : can(cidrnetmask(cidr)) && cidr != "0.0.0.0/0"])
    error_message = "allowed_public_ingress_cidr_blocks must contain valid CIDRs and must not include 0.0.0.0/0."
  }
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
