resource "aws_vpc" "ecs_sample" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "ecs-sample"
  }
}

resource "aws_subnet" "public0" {
  cidr_block              = "10.0.0.0/24"
  vpc_id                  = aws_vpc.ecs_sample.id
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1a"
}

resource "aws_subnet" "public1" {
  cidr_block              = "10.0.1.0/24"
  vpc_id                  = aws_vpc.ecs_sample.id
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1c"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.ecs_sample.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ecs_sample.id
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public0" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public0.id
}

resource "aws_route_table_association" "public1" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public1.id
}

resource "aws_subnet" "private0" {
  cidr_block        = "10.0.2.0/24"
  vpc_id            = aws_vpc.ecs_sample.id
  availability_zone = "ap-northeast-1a"
}

resource "aws_subnet" "private1" {
  cidr_block        = "10.0.3.0/24"
  vpc_id            = aws_vpc.ecs_sample.id
  availability_zone = "ap-northeast-1c"
}

resource "aws_route_table" "private0" {
  vpc_id = aws_vpc.ecs_sample.id
}

resource "aws_route_table" "private1" {
  vpc_id = aws_vpc.ecs_sample.id
}

resource "aws_route_table_association" "private0" {
  subnet_id      = aws_subnet.private0.id
  route_table_id = aws_route_table.private0.id
}

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private1.id
}

resource "aws_eip" "ngw0" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_eip" "ngw1" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "ngw0" {
  allocation_id = aws_eip.ngw0.id
  subnet_id     = aws_subnet.public0.id
  depends_on    = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "ngw1" {
  allocation_id = aws_eip.ngw1.id
  subnet_id     = aws_subnet.public1.id
  depends_on    = [aws_internet_gateway.igw]
}

resource "aws_route" "private0" {
  route_table_id         = aws_route_table.private0.id
  nat_gateway_id         = aws_nat_gateway.ngw0.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private1" {
  route_table_id         = aws_route_table.private1.id
  nat_gateway_id         = aws_nat_gateway.ngw1.id
  destination_cidr_block = "0.0.0.0/0"
}
