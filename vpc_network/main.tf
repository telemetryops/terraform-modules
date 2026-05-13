data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  requested_az_count          = max(var.az_count, length(var.public_subnet_cidr_blocks), length(var.private_subnet_cidr_blocks))
  selected_availability_zones = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, local.requested_az_count)

  common_tags = merge(
    var.tags,
    {
      ManagedBy = "terraform"
      Module    = "vpc_network"
    }
  )

  interface_endpoint_services = merge(
    var.enable_iot_endpoints ? {
      iot_data = {
        service_name      = "com.amazonaws.${data.aws_region.current.name}.iot.data"
        security_group_id = aws_security_group.iot_endpoint.id
      }
      iot_credentials = {
        service_name      = "com.amazonaws.${data.aws_region.current.name}.iot.credentials"
        security_group_id = aws_security_group.iot_endpoint.id
      }
    } : {},
    var.enable_timestream_endpoints ? {
      timestream_write = {
        service_name      = "com.amazonaws.${data.aws_region.current.name}.timestream.ingest"
        security_group_id = aws_security_group.timestream_endpoint.id
      }
      timestream_query = {
        service_name      = "com.amazonaws.${data.aws_region.current.name}.timestream.query"
        security_group_id = aws_security_group.timestream_endpoint.id
      }
    } : {},
    {
      for name, service in var.additional_interface_endpoints : name => {
        service_name      = service.service_name
        security_group_id = aws_security_group.additional_endpoint[name].id
      }
    }
  )
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = var.name_prefix
  })
}

resource "aws_internet_gateway" "main" {
  count = length(var.public_subnet_cidr_blocks) > 0 ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-igw"
  })
}

resource "aws_subnet" "public" {
  for_each = {
    for index, cidr in var.public_subnet_cidr_blocks : index => cidr
  }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = local.selected_availability_zones[tonumber(each.key)]
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-public-${tonumber(each.key) + 1}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  for_each = {
    for index, cidr in var.private_subnet_cidr_blocks : index => cidr
  }

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = local.selected_availability_zones[tonumber(each.key)]

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-private-${tonumber(each.key) + 1}"
    Tier = "private"
  })
}

resource "aws_route_table" "public" {
  count = length(var.public_subnet_cidr_blocks) > 0 ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-public"
  })
}

resource "aws_route" "public_internet" {
  count = length(var.public_subnet_cidr_blocks) > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main[0].id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-nat"
  })
}

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-nat"
  })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-private"
  })
}

resource "aws_route" "private_nat" {
  count = var.enable_nat_gateway ? 1 : 0

  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[0].id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "lambda" {
  name        = "${var.name_prefix}-lambda"
  description = "Private Lambda workloads inside the TelemetryOps VPC."
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-lambda"
  })
}

resource "aws_security_group" "iot_endpoint" {
  name        = "${var.name_prefix}-iot-endpoint"
  description = "IoT Core interface endpoints reachable from private Lambdas."
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-iot-endpoint"
  })
}

resource "aws_security_group" "timestream_endpoint" {
  name        = "${var.name_prefix}-timestream-endpoint"
  description = "Timestream interface endpoints reachable from private Lambdas."
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-timestream-endpoint"
  })
}

resource "aws_security_group" "additional_endpoint" {
  for_each = var.additional_interface_endpoints

  name        = "${var.name_prefix}-${each.key}-endpoint"
  description = "Additional interface endpoint ${each.key} reachable from private Lambdas."
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-${each.key}-endpoint"
  })
}

resource "aws_vpc_security_group_egress_rule" "lambda_to_iot_endpoint" {
  count = var.enable_iot_endpoints ? 1 : 0

  security_group_id            = aws_security_group.lambda.id
  referenced_security_group_id = aws_security_group.iot_endpoint.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
  description                  = "Allow private Lambdas to reach IoT Core VPC endpoints."
}

resource "aws_vpc_security_group_egress_rule" "lambda_to_timestream_endpoint" {
  count = var.enable_timestream_endpoints ? 1 : 0

  security_group_id            = aws_security_group.lambda.id
  referenced_security_group_id = aws_security_group.timestream_endpoint.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
  description                  = "Allow private Lambdas to reach Timestream VPC endpoints."
}

resource "aws_vpc_security_group_egress_rule" "lambda_to_additional_endpoint" {
  for_each = var.additional_interface_endpoints

  security_group_id            = aws_security_group.lambda.id
  referenced_security_group_id = aws_security_group.additional_endpoint[each.key].id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
  description                  = "Allow private Lambdas to reach additional VPC endpoint ${each.key}."
}

resource "aws_vpc_security_group_egress_rule" "lambda_nat_https" {
  for_each = toset(var.enable_nat_gateway ? var.nat_https_egress_cidr_blocks : [])

  security_group_id = aws_security_group.lambda.id
  cidr_ipv4         = each.value
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
  description       = "Allow private Lambdas to reach approved HTTPS destinations through NAT."
}

resource "aws_vpc_security_group_ingress_rule" "iot_endpoint_from_lambda" {
  count = var.enable_iot_endpoints ? 1 : 0

  security_group_id            = aws_security_group.iot_endpoint.id
  referenced_security_group_id = aws_security_group.lambda.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
  description                  = "Allow private Lambdas to reach IoT Core endpoints."
}

resource "aws_vpc_security_group_ingress_rule" "timestream_endpoint_from_lambda" {
  count = var.enable_timestream_endpoints ? 1 : 0

  security_group_id            = aws_security_group.timestream_endpoint.id
  referenced_security_group_id = aws_security_group.lambda.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
  description                  = "Allow private Lambdas to reach Timestream endpoints."
}

resource "aws_vpc_security_group_ingress_rule" "additional_endpoint_from_lambda" {
  for_each = var.additional_interface_endpoints

  security_group_id            = aws_security_group.additional_endpoint[each.key].id
  referenced_security_group_id = aws_security_group.lambda.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
  description                  = "Allow private Lambdas to reach additional VPC endpoint ${each.key}."
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoint_services

  vpc_id              = aws_vpc.main.id
  service_name        = each.value.service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for subnet in aws_subnet.private : subnet.id]
  security_group_ids  = [each.value.security_group_id]
  private_dns_enabled = var.interface_endpoint_private_dns_enabled

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-${each.key}"
  })
}
