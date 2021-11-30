data "aws_route53_zone" "sakura_cloud_education_touch_demo_com" {
  name = "sakura-cloud-education-touch-demo.com"
}

resource "aws_route53_record" "sample" {
  zone_id = data.aws_route53_zone.sakura_cloud_education_touch_demo_com.zone_id
  name    = data.aws_route53_zone.sakura_cloud_education_touch_demo_com.name
  type    = "A"

  alias {
    evaluate_target_health = true
    name                   = aws_lb.sample.dns_name
    zone_id                = aws_lb.sample.zone_id
  }
}

resource "aws_route53_record" "nginx" {
  zone_id = data.aws_route53_zone.sakura_cloud_education_touch_demo_com.zone_id
  name    = "nginx.${data.aws_route53_zone.sakura_cloud_education_touch_demo_com.name}"
  type    = "A"

  alias {
    evaluate_target_health = true
    name                   = aws_lb.sample.dns_name
    zone_id                = aws_lb.sample.zone_id
  }
}

output "domain_name" {
  value = aws_route53_record.sample.name
}
