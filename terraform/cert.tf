resource "aws_acm_certificate" "sample" {
  domain_name               = aws_route53_record.sample.name
  subject_alternative_names = ["*.${aws_route53_record.sample.name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "sample_cert_validation" {
  zone_id = data.aws_route53_zone.sakura_cloud_education_touch_demo_com.zone_id
  ttl     = 60
  name    = tolist(aws_acm_certificate.sample.domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.sample.domain_validation_options)[0].resource_record_type
  records = [tolist(aws_acm_certificate.sample.domain_validation_options)[0].resource_record_value]
}

resource "aws_acm_certificate_validation" "sample" {
  certificate_arn         = aws_acm_certificate.sample.arn
  validation_record_fqdns = [aws_route53_record.sample_cert_validation.fqdn]
}
