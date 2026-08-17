resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_a_cidr
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "${var.name_prefix}-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_b_cidr
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "${var.name_prefix}-public-b"
  }
}

resource "aws_subnet" "app_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.app_a_cidr
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "${var.name_prefix}-app-a"
  }

}

resource "aws_subnet" "app_b" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.app_b_cidr
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "${var.name_prefix}-app-b"
  }
}

resource "aws_subnet" "data_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.data_a_cidr
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "${var.name_prefix}-data-a"
  }
}

resource "aws_subnet" "data_b" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.data_b_cidr
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "${var.name_prefix}-data-b"
  }
}