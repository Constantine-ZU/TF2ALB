
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
    Name = "0_0_VPC"
  }
}

resource "aws_subnet" "subnet_10_0" {
  vpc_id            = aws_vpc.vpc_0_0.id
  cidr_block        = "10.10.10.0/24"
    availability_zone = "eu-north-1a" 
  map_public_ip_on_launch = true

  tags = {
    Name = "Subnet_10_0_24"
  }
}

resource "aws_subnet" "subnet_20_0" {
  vpc_id            = aws_vpc.vpc_0_0.id
  cidr_block        = "10.10.20.0/24"
  availability_zone = "eu-north-1b"  
  map_public_ip_on_launch = true

  tags = {
    Name = "Subnet_10_0_24"
  }
}

resource "aws_internet_gateway" "default_ig" {
  vpc_id = aws_vpc.vpc_0_0.id

  tags = {
    Name = "defaultIGW"
  }
}

resource "aws_route_table" "default_rt" {
  vpc_id = aws_vpc.vpc_0_0.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default_ig.id
  }

  tags = {
    Name = "defaultRouteTable"
  }
}

resource "aws_route_table_association" "default_subnet_10_0" {
  subnet_id      = aws_subnet.subnet_10_0.id
  route_table_id = aws_route_table.default_rt.id
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



resource "aws_route_table_association" "default_subnet_20_0" {
  subnet_id      = aws_subnet.subnet_20_0.id
  route_table_id = aws_route_table.default_rt.id
}

resource "aws_instance" "Instance_20_7" {
  ami                     = "ami-0705384c0b33c194c"
  instance_type           = "t3.micro"
  key_name                = "pair-key"
  subnet_id               = aws_subnet.subnet_20_0.id  
  vpc_security_group_ids  = [aws_security_group.sg_80_433.id]
  associate_public_ip_address = true
  private_ip              = "10.10.20.7"
  iam_instance_profile = "IAM_CERT_ROLE"  

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${path.module}/pair-key.pem")
    host        = self.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y postgresql-client", 
      "sudo snap install aws-cli --classic",
      "aws s3 cp s3://constantine-z-2/webaws_pam4_com_2024_05_13.pfx ./webaws_pam4_com_2024_05_13.pfx",
      "sudo mv ./webaws_pam4_com_2024_05_13.pfx /etc/ssl/certs/webaws_pam4_com.pfx",
      "sudo chmod 600 /etc/ssl/certs/webaws_pam4_com.pfx",
      "sudo mkdir -p /var/www/BlazorForTF",
      "curl -L -o BlazorForTF.tar https://constantine-z.s3.eu-north-1.amazonaws.com/BlazorForTF.tar",
      "sudo tar -xf BlazorForTF.tar -C /var/www/BlazorForTF",
      "sudo chmod +x /var/www/BlazorForTF/BlazorForTF",
      "sudo chmod -R 755 /var/www/BlazorForTF/wwwroot/",
      "echo '[Unit]\nDescription=BlazorForTF Web App\n\n[Service]\nWorkingDirectory=/var/www/BlazorForTF\nExecStart=/var/www/BlazorForTF/BlazorForTF\nRestart=always\nRestartSec=10\nSyslogIdentifier=blazorfortf\n\n[Install]\nWantedBy=multi-user.target' | sudo tee /etc/systemd/system/blazorfortf.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable blazorfortf",
      "sudo systemctl start blazorfortf",
      "export PGPASSWORD=$(aws rds generate-db-auth-token --hostname ${aws_db_instance.pg_instance.endpoint} --region eu-north-1 --username dbuser)",
      "psql \"host=${aws_db_instance.pg_instance.endpoint} dbname=dbwebaws user=dbuser password=$PGPASSWORD\" -c \"GRANT rds_iam TO dbuser;\""
  
    ]
  }

 provisioner "local-exec" {
    command = "python3 update_hetzner.py"
    environment = {
      HETZNER_DNS_KEY    = var.hetzner_dns_key
      NEW_IP             = self.public_ip
      HETZNER_RECORD_NAME = "webaws7"
      HETZNER_DOMAIN_NAME = "pam4.com"
    }
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
  iam_instance_profile = "IAM_CERT_ROLE"  

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${path.module}/pair-key.pem")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
    "sudo apt-get update",
    "sudo snap install aws-cli --classic",  
    "aws s3 cp s3://constantine-z-2/webaws_pam4_com_2024_05_13.pfx ./webaws_pam4_com_2024_05_13.pfx",  
    "sudo mv ./webaws_pam4_com_2024_05_13.pfx /etc/ssl/certs/webaws_pam4_com.pfx", 
    "sudo chmod 600 /etc/ssl/certs/webaws_pam4_com.pfx", 
    "sudo mkdir -p /var/www/BlazorForTF",
    "curl -L -o BlazorForTF.tar https://constantine-z.s3.eu-north-1.amazonaws.com/BlazorForTF.tar",
    "sudo tar -xf BlazorForTF.tar -C /var/www/BlazorForTF",
    "sudo chmod +x /var/www/BlazorForTF/BlazorForTF",
    "sudo chmod -R 755 /var/www/BlazorForTF/wwwroot/",
    "echo '[Unit]\nDescription=BlazorForTF Web App\n\n[Service]\nWorkingDirectory=/var/www/BlazorForTF\nExecStart=/var/www/BlazorForTF/BlazorForTF\nRestart=always\nRestartSec=10\nSyslogIdentifier=blazorfortf\n\n[Install]\nWantedBy=multi-user.target' | sudo tee /etc/systemd/system/blazorfortf.service",
    "sudo systemctl daemon-reload",
    "sudo systemctl enable blazorfortf",
    "sudo systemctl start blazorfortf"
    ]
  }
   provisioner "local-exec" {
    command = "python3 update_hetzner.py"
    environment = {
      HETZNER_DNS_KEY    = var.hetzner_dns_key
      NEW_IP             = self.public_ip
      HETZNER_RECORD_NAME = "webaws6"
      HETZNER_DOMAIN_NAME = "pam4.com"
    }
  }

  tags = {
    Name = "Ubuntu-ALB-10-6"
  }
}
