data "aws_availability_zones" "available" {
  state = "available"
}

//The Primary VPC
resource "aws_vpc" "SpotHero-VPC" {
  cidr_block       = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "SpotHero"
  }
}

//Subnets

//Simple IG
resource "aws_internet_gateway" "SpotHero-gateway" {
  vpc_id = aws_vpc.SpotHero-VPC.id

  tags = {
    Name = "SpotHero-InternetGateway"
  }
}

//Public Subnet
resource "aws_subnet" "SpotHero-subnet-Public1" {
  vpc_id     = aws_vpc.SpotHero-VPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "SpotHero-subnet-Publi1"
  }
}

resource "aws_subnet" "SpotHero-subnet-Public2" {
  vpc_id     = aws_vpc.SpotHero-VPC.id
  cidr_block = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "SpotHero-subnet-Public2"
  }
}

resource "aws_route_table" "SpotHero-RouteTable-Public" {
  vpc_id = aws_vpc.SpotHero-VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.SpotHero-gateway.id
  }

  tags = {
    Name = "SpotHero-RouteTable"
  }
}

resource "aws_route_table_association" "SpotHero-RouteTable-Public1" {
  subnet_id      = aws_subnet.SpotHero-subnet-Public1.id
  route_table_id = aws_route_table.SpotHero-RouteTable-Public.id
}

resource "aws_route_table_association" "SpotHero-RouteTable-Public2" {
  subnet_id      = aws_subnet.SpotHero-subnet-Public2.id
  route_table_id = aws_route_table.SpotHero-RouteTable-Public.id
}

resource "aws_security_group" "Spothero-Default-SecurityGroup" {
  name        = "Test-default-sg"
  description = "Default security group to allow inbound/outbound from the VPC"
  vpc_id      = aws_vpc.SpotHero-VPC.id
  depends_on  = [aws_vpc.SpotHero-VPC]

  ingress {
    from_port = "0"zzz
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = "true"
  }
}