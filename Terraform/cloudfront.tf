/* -------------------------------------------------------------------------- */
/*                             SSL/TLS CERTIFICATE                            */
/* -------------------------------------------------------------------------- */
resource "aws_acm_certificate" "website-certificate" {
  domain_name       = var.domain-name
  validation_method = "DNS"
}


/* -------------------------------------------------------------------------- */
/*                                 CLOUDFRONT                                 */
/* -------------------------------------------------------------------------- */
resource "aws_cloudfront_origin_access_control" "origin-access-control" {
  name                              = "${var.project-name}-access-control"
  description                       = "${var.project-name} Cloudfront Origin Access Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3-distribution" {
  origin {
    domain_name              = aws_s3_bucket.website-bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.origin-access-control.id
    origin_id                = aws_s3_bucket.website-bucket.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = var.project-name
  default_root_object = "index.html"


  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.website-bucket.id
    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = aws_s3_bucket.website-bucket.id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.website-bucket.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.website-certificate.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}


