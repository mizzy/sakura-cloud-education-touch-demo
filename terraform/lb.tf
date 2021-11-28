resource "aws_s3_bucket" "alb_log" {
  bucket = "alb-log-of-ecs-sample"
  lifecycle_rule {
    enabled = true

    expiration {
      days = "180"
    }
  }
}

resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log.json
}

data "aws_iam_policy_document" "alb_log" {
  version = "2012-10-17"

  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["582318560864"]
    }
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]
  }
}

module "http_sg" {
  source      = "./modules/security_group"
  name        = "http-sg"
  vpc_id      = aws_vpc.ecs_sample.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}

module "https_sg" {
  source      = "./modules/security_group"
  name        = "https-sg"
  vpc_id      = aws_vpc.ecs_sample.id
  port        = 443
  cidr_blocks = ["0.0.0.0/0"]
}

module "https_redirect_sg" {
  source      = "./modules/security_group"
  name        = "http-redirect-sg"
  vpc_id      = aws_vpc.ecs_sample.id
  port        = 8080
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_lb" "sample" {
  name                       = "sample"
  load_balancer_type         = "application"
  internal                   = false
  idle_timeout               = 60
  enable_deletion_protection = false

  subnets = [
    aws_subnet.public0.id,
    aws_subnet.public1.id,
  ]

  access_logs {
    bucket  = aws_s3_bucket.alb_log.id
    enabled = true
    prefix  = "alb-logs"
  }

  security_groups = [
    module.http_sg.security_group_id,
    module.https_sg.security_group_id,
    module.https_redirect_sg.security_group_id,
  ]
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.sample.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.sample.arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_target_group" "sample" {
  name                 = "sample"
  target_type          = "ip"
  vpc_id               = aws_vpc.ecs_sample.id
  port                 = 80
  protocol             = "HTTP"
  deregistration_delay = 300

  health_check {
    path                = "/"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  depends_on = [aws_lb.sample]
}

resource "aws_lb_listener_rule" "sample" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sample.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

output "alb_dns_name" {
  value = aws_lb.sample.dns_name
}
