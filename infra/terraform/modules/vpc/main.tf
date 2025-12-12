data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # Tomamos las primeras N AZs disponibles
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.name_prefix}-vpc"
    Project     = var.name_prefix
    Environment = "dev"
  }
}

# Internet Gateway para las subnets públicas
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "${var.name_prefix}-igw"
    Project     = var.name_prefix
    Environment = "dev"
  }
}

# Subnets públicas (una por AZ)
resource "aws_subnet" "public" {
  for_each = {
    for idx, az in local.azs : idx => az
  }

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, each.key) # /24
  map_public_ip_on_launch = true

  tags = {
    Name                        = "${var.name_prefix}-public-${each.value}"
    Project                     = var.name_prefix
    Environment                 = "dev"
    "kubernetes.io/role/elb"    = "1"
    "kubernetes.io/cluster/${var.name_prefix}-eks" = "shared"
  }
}

# Route table para subnets públicas
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "${var.name_prefix}-public-rt"
    Project     = var.name_prefix
    Environment = "dev"
  }
}

# Ruta a internet por el IGW
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# Asocia todas las subnets públicas a esta route table
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}
