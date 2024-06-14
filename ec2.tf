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

  provisioner "file" {
    source      = "setup_instance.sh"
    destination = "/tmp/setup_instance.sh"
  }
  provisioner "file" {
    source      = "restore_pg_dump.sh"
    destination = "/tmp/restore_pg_dump.sh"
  }
  provisioner "file" {
  content     = var.db_password
  destination = "/tmp/db_password"
}
  
  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/setup_instance.sh /usr/local/bin/setup_instance.sh",
      "sudo chmod +x /usr/local/bin/setup_instance.sh",
      "export S3_PATH='s3://constantine-z-2/'",
      "export PFX_FILE_NAME='webaws_pam4_com_2024_05_13.pfx'",
      "export APP_NAME='BlazorAut'",
      "export S3_BASE_URL='https://constantine-z.s3.eu-north-1.amazonaws.com'",
      "export DB_HOST='pgaws.pam4.com'",
      "export DB_USER='dbuser'",
      "DB_PASS=$(cat /tmp/db_password)",
      "export DB_PASS",
      "export DB_NAME='dbwebaws'"
      ,"sudo mv /tmp/restore_pg_dump.sh /usr/local/bin/restore_pg_dump.sh"
      ,"sudo chmod +x /usr/local/bin/restore_pg_dump.sh"
      ,"sudo -E /usr/local/bin/restore_pg_dump.sh"
      ,"sudo -E /usr/local/bin/setup_instance.sh",
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
depends_on = [aws_db_instance.pg_instance]
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

  provisioner "file" {
    source      = "setup_instance.sh"
    destination = "/tmp/setup_instance.sh"
  }
    provisioner "file" {
    content     = var.db_password
    destination = "/tmp/db_password"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/setup_instance.sh /usr/local/bin/setup_instance.sh",
      "sudo chmod +x /usr/local/bin/setup_instance.sh",
      "export S3_PATH='s3://constantine-z-2/'",
      "export PFX_FILE_NAME='webaws_pam4_com_2024_05_13.pfx'",
      "export APP_NAME='BlazorAut'",
      "export S3_BASE_URL='https://constantine-z.s3.eu-north-1.amazonaws.com'",
      "export DB_HOST='pgaws.pam4.com'",
      "export DB_USER='dbuser'",
      "DB_PASS=$(cat /tmp/db_password)",
      "export DB_PASS",
      "export DB_NAME='dbwebaws'"
      ,"sudo -E /usr/local/bin/setup_instance.sh"
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
  depends_on = [aws_instance.Instance_20_7]

}
