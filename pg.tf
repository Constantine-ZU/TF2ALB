resource "aws_db_instance" "default" {
  identifier = "mypostgresdb"
  engine = "postgres"
  engine_version = "13.2"
  instance_class = "db.t2.micro"
  allocated_storage = 20
  username = "dbuser"
  password = var.db_password
  db_subnet_group_name = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.pg_sg.id]
  skip_final_snapshot = true
}

resource "aws_db_subnet_group" "default" {
  name = "main"
  subnet_ids = [aws_subnet.subnet_10_0.id, aws_subnet.subnet_20_0.id]

  tags = {
    Name = "My DB subnet group"
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

  ingress { #for access from instances
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
