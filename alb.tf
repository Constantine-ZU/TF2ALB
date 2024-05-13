resource "aws_lb" "app_lb_webaws_pam4" {
  name               = "my-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_80_433.id]
  subnets            = [aws_subnet.subnet_10_0.id, aws_subnet.subnet_20_0.id]

  enable_deletion_protection = false

provisioner "local-exec" {
    command = "python3 update_hetzner.py"
    environment = {
      HETZNER_DNS_KEY   = var.hetzner_dns_key
      HETZNER_C_NAME    = self.dns_name
      HETZNER_RECORD_NAME = "webaws"
      HETZNER_DOMAIN_NAME = "pam4.com"
    }
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



resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app_lb_webaws_pam4.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:eu-north-1:637423446150:certificate/f02aeb60-3ec1-4c7c-866e-41c27c34ce90"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
