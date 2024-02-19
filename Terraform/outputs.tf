output "connect-codepipeline-with-github" {
  value = "Step1: Open Pipeline settings in AWS Console and Complete the Pending Github Connection"
}

output "add-cname-records" {
  value = "Step2: Add the above CNAME Record in you domain NameServer Records"
}

output "attach-the-certificate" {
  value = "Step3: Depending on your Domain provider Certificate validation can take few minutes to few days after verification just again run the terraform apply to set up your certificate with Cloudfront. "
}

output "cloudfront-url" {
  value = aws_cloudfront_distribution.s3-distribution.domain_name
}

output "certificate-cname_record" {
  description = "Add this record in your domain nameserver"
  value = { for dvo in aws_acm_certificate.website-certificate.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
  } }
}

