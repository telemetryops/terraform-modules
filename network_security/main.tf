locals {
  common_tags = merge(
    var.tags,
    {
      ManagedBy = "terraform"
      Module    = "network_security"
    }
  )

  data_store_ports = toset([for port in var.data_store_ports : tostring(port)])
}

resource "aws_security_group" "lambda_private" {
  name        = "${var.name_prefix}-lambda-private"
  description = "Private Lambda workloads. No ingress; explicit egress only."
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-lambda-private"
  })
}

resource "aws_vpc_security_group_egress_rule" "lambda_https" {
  for_each = toset(var.https_egress_cidr_blocks)

  security_group_id = aws_security_group.lambda_private.id
  cidr_ipv4         = each.value
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
  description       = "HTTPS egress to explicitly approved network ranges."
}

resource "aws_security_group" "vpc_endpoint" {
  name        = "${var.name_prefix}-vpc-endpoint"
  description = "Interface VPC endpoints reachable only from private Lambda workloads."
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-vpc-endpoint"
  })
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoint_from_lambda" {
  security_group_id            = aws_security_group.vpc_endpoint.id
  referenced_security_group_id = aws_security_group.lambda_private.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
  description                  = "Allow private Lambdas to reach interface endpoints."
}

resource "aws_security_group" "data_store" {
  name        = "${var.name_prefix}-data-store"
  description = "Private data stores reachable only from private Lambda workloads."
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-data-store"
  })
}

resource "aws_vpc_security_group_ingress_rule" "data_store_from_lambda" {
  for_each = local.data_store_ports

  security_group_id            = aws_security_group.data_store.id
  referenced_security_group_id = aws_security_group.lambda_private.id
  from_port                    = tonumber(each.value)
  ip_protocol                  = "tcp"
  to_port                      = tonumber(each.value)
  description                  = "Allow private Lambdas to reach private data stores."
}

resource "aws_network_acl" "private_workload" {
  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-private-workload"
  })
}

resource "aws_network_acl_rule" "private_ingress_vpc" {
  network_acl_id = aws_network_acl.private_workload.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_block
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "private_egress_vpc" {
  network_acl_id = aws_network_acl.private_workload.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_block
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "private_egress_https" {
  for_each = {
    for index, cidr in var.https_egress_cidr_blocks : cidr => 110 + index
  }

  network_acl_id = aws_network_acl.private_workload.id
  rule_number    = each.value
  egress         = true
  protocol       = "6"
  rule_action    = "allow"
  cidr_block     = each.key
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "private_ingress_ephemeral" {
  for_each = {
    for index, cidr in var.https_egress_cidr_blocks : cidr => 110 + index
  }

  network_acl_id = aws_network_acl.private_workload.id
  rule_number    = each.value
  egress         = false
  protocol       = "6"
  rule_action    = "allow"
  cidr_block     = each.key
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl" "public_edge" {
  count = length(var.public_subnet_ids) > 0 ? 1 : 0

  vpc_id     = var.vpc_id
  subnet_ids = var.public_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-public-edge"
  })
}

resource "aws_network_acl_rule" "public_edge_https_ingress" {
  for_each = length(var.public_subnet_ids) > 0 ? {
    for index, cidr in var.allowed_public_ingress_cidr_blocks : cidr => 100 + index
  } : {}

  network_acl_id = aws_network_acl.public_edge[0].id
  rule_number    = each.value
  egress         = false
  protocol       = "6"
  rule_action    = "allow"
  cidr_block     = each.key
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "public_edge_http_ingress" {
  for_each = length(var.public_subnet_ids) > 0 ? {
    for index, cidr in var.allowed_public_ingress_cidr_blocks : cidr => 200 + index
  } : {}

  network_acl_id = aws_network_acl.public_edge[0].id
  rule_number    = each.value
  egress         = false
  protocol       = "6"
  rule_action    = "allow"
  cidr_block     = each.key
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "public_edge_ephemeral_egress" {
  for_each = length(var.public_subnet_ids) > 0 ? {
    for index, cidr in var.allowed_public_ingress_cidr_blocks : cidr => 300 + index
  } : {}

  network_acl_id = aws_network_acl.public_edge[0].id
  rule_number    = each.value
  egress         = true
  protocol       = "6"
  rule_action    = "allow"
  cidr_block     = each.key
  from_port      = 1024
  to_port        = 65535
}
