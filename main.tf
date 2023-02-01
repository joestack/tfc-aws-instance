terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = {
      version = "~> 4.35.0"
    }
  }
}

provider "vault" {
  address   = var.vault_public_url
  auth_login_userpass {
    username = var.vault_username
    password = var.vault_password
    namespace = var.vault_namespace
  }
}

data "vault_aws_access_credentials" "creds" {
  backend = "aws"
  role    = "deploy"
}

provider "aws" {
    region = var.aws_region
    access_key = data.vault_aws_access_credentials.creds.access_key
    secret_key = data.vault_aws_access_credentials.creds.secret_key
}

# Network & Routing
# VPC 

resource "aws_vpc" "hashicorp_vpc" {
  cidr_block           = var.network_address_space
  enable_dns_hostnames = "true"

  tags = {
    Name = "${var.name}-vpc"
  }
}

# Internet Gateways and route table

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.hashicorp_vpc.id
}

resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.hashicorp_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name        = "${var.name}-igw"
  }
}

resource "aws_subnet" "dmz_subnet" {
  vpc_id                  = aws_vpc.hashicorp_vpc.id
  cidr_block              = cidrsubnet(var.network_address_space, 8, 1)
  map_public_ip_on_launch = "true"
  #availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "dmz-subnet"
  }
}

resource "aws_route_table_association" "dmz-subnet" {
  subnet_id      = aws_subnet.dmz_subnet.*.id[0]
  route_table_id = aws_route_table.rtb.id
}

## Access and Security Groups

resource "aws_security_group" "bastionhost" {
  name        = "${var.name}-bastionhost-sg"
  description = "Bastionhosts"
  vpc_id      = aws_vpc.hashicorp_vpc.id
}

resource "aws_security_group_rule" "jh-ssh" {
  security_group_id = aws_security_group.bastionhost.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "jh-egress" {
  security_group_id = aws_security_group.bastionhost.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_instance" "bastionhost" {
  ami                         = var.ami_id #ami-0f29c8402f8cce65c
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.dmz_subnet.id
  private_ip                  = cidrhost(aws_subnet.dmz_subnet.cidr_block, 10)
  associate_public_ip_address = "true"
  vpc_security_group_ids      = [aws_security_group.bastionhost.id]
  key_name                    = var.pub_key
  
  tags = {
    Name        = "bh-instance"
  }
}
