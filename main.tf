
terraform {
  backend "s3" {
    bucket         = "constantine-z"
    region         = "eu-north-1"
    # dynamodb_table = "terraform-locks"
    encrypt        = true
    key            = "tf2alb.tfstate"
  }
  required_version = ">= 1.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.64.0"
    }
  }
}



provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key

  region     = "eu-north-1"
}


resource "aws_vpc" "vpc_0_0" {
  cidr_block = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "defaultVPC"
  }
}

resource "aws_subnet" "subnet_10_0" {
  vpc_id            = aws_vpc.vpc_0_0.id
  cidr_block        = "10.10.10.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "defaultSubnet"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.vpc_0_0.id

  tags = {
    Name = "defaultIGW"
  }
}

resource "aws_route_table" "default" {
  vpc_id = aws_vpc.vpc_0_0.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }

  tags = {
    Name = "defaultRouteTable"
  }
}

resource "aws_route_table_association" "default" {
  subnet_id      = aws_subnet.subnet_10_0.id
  route_table_id = aws_route_table.default.id
}


resource "aws_security_group" "sg_80_433" {
  name        = "launch-wizard"
  description = "launch-wizard security group for EC2 instance"
  vpc_id      = aws_vpc.vpc_0_0.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "subnet_20_0" {
  vpc_id            = aws_vpc.vpc_0_0.id
  cidr_block        = "10.10.20.0/24"
  availability_zone = "eu-north-1b"  # Дополнительный субнет в другой зоне
  map_public_ip_on_launch = true

  tags = {
    Name = "additionalSubnet"
  }
}

resource "aws_route_table_association" "default_subnet_20_0" {
  subnet_id      = aws_subnet.subnet_20_0.id
  route_table_id = aws_route_table.default.id
}

resource "aws_instance" "Instance_20_7" {
  ami                     = "ami-0705384c0b33c194c"
  instance_type           = "t3.micro"
  key_name                = "pair-key"
  subnet_id               = aws_subnet.subnet_20_0.id  
  vpc_security_group_ids  = [aws_security_group.sg_80_433.id]
  associate_public_ip_address = true
  private_ip              = "10.10.20.7"

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${path.module}/pair-key.pem")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo snap install aws-cli --classic"
    ]
  }

  tags = {
    Name = "Ubuntu-ALB-10-7"
  }
}

resource "aws_instance" "Instance_10_6" {
  ami                     = "ami-0705384c0b33c194c"
  instance_type           = "t3.micro"
  key_name                = "pair-key"
  subnet_id               = aws_subnet.subnet_10_0.id 
  vpc_security_group_ids  = [aws_security_group.sg_80_433.id]
  associate_public_ip_address = true
  private_ip              = "10.10.10.6"

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${path.module}/pair-key.pem")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo snap install aws-cli --classic"
    ]
  }

  tags = {
    Name = "Ubuntu-ALB-10-6"
  }
}