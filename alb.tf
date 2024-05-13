resource "aws_lb" "app_lb" {
  name               = "my-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_80_433.id]
  subnets            = [aws_subnet.subnet_10_0.id, aws_subnet.subnet_10_1.id]

  enable_deletion_protection = false
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_lb_target_group" "app_tg" {
  name     = "app-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_0_0.id

  health_check {
    protocol           = "HTTP"
    path               = "/"
    interval           = 30
    timeout            = 5
    healthy_threshold  = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "tg_attachment_10_6" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.Instance_10_6.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "tg_attachment_10_7" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.Instance_20_7.id
  port             = 80
}

resource "aws_subnet" "subnet_10_1" {
  vpc_id                  = aws_vpc.vpc_0_0.id
  cidr_block              = "10.10.20.0/24"
  availability_zone       = "eu-north-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "additionalSubnet"
  }
}

resource "aws_acm_certificate" "cert" {
  private_key       = aws_s3_object.private_key_object.body
  certificate_body  = aws_s3_object.certificate_object.body
  certificate_chain = aws_s3_object.certificate_chain_object.body # Используйте этот параметр, если есть цепочка сертификатов

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_s3_object" "certificate_object" {
  bucket = "constantine-z-2"
  key    = "webaws_pam4_com_2024_05_13.pfx"
}

resource "aws_s3_object" "private_key_object" {
  bucket = "constantine-z-2"
  key    = "webaws_pam4_com_2024_05_13.key"
}
