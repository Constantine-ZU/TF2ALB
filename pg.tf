resource "aws_db_instance" "pg_instance" {
  identifier              = "pgdbwebaws"
  engine                  = "postgres"
  engine_version          = "16.2"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  username                = "dbuser"
  password                = var.db_password
  db_name                 = "dbwebaws"
  db_subnet_group_name    = aws_db_subnet_group.pg_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.pg_sg.id]
  skip_final_snapshot     = true
  publicly_accessible     = true
  iam_database_authentication_enabled = true

  provisioner "local-exec" {
    command = <<EOT
# Install PostgreSQL client
sudo apt-get update
sudo apt-get install -y postgresql-client

# Set environment variables
export HOSTNAME=$(echo ${self.endpoint} | cut -d':' -f1)
export PGPASSWORD=$(aws rds generate-db-auth-token --hostname $HOSTNAME --port 5432 --region eu-north-1 --username ${self.username})

# Download and restore the backup
aws s3 cp s3://constantine-z-2/dbwebaws_backup.dump /tmp/dbwebaws_backup.dump
pg_restore -h $HOSTNAME -U ${self.username} -d ${self.db_name} -v /tmp/dbwebaws_backup.dump

# Grant IAM role
psql "host=$HOSTNAME dbname=${self.db_name} user=${self.username} password=$PGPASSWORD" -c "GRANT rds_iam TO dbuser;"
EOT
  }
}

resource "aws_db_subnet_group" "pg_subnet_group" {
  name = "main"
  subnet_ids = [aws_subnet.subnet_10_0.id, aws_subnet.subnet_20_0.id]

  tags = {
    Name = "Postgres DB subnet group"
  }
}

resource "aws_security_group" "pg_sg" {
  name = "rds-sg"
  description = "Security group for RDS PostgreSQL instance"
  vpc_id = aws_vpc.vpc_0_0.id

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = local.cidr_blocks
  }

  ingress { # for access from instances
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = [aws_security_group.sg_80_433.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "null_resource" "update_dns" {
  triggers = {
    endpoint = aws_db_instance.pg_instance.endpoint
  }

  provisioner "local-exec" {
    command = "python3 update_hetzner.py"
    environment = {
      HETZNER_DNS_KEY = var.hetzner_dns_key
      HETZNER_C_NAME  = aws_db_instance.pg_instance.endpoint
      HETZNER_RECORD_NAME = "pgaws"
      HETZNER_DOMAIN_NAME = "pam4.com"
    }
  }
}
