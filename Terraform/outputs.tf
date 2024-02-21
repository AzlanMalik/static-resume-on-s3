output "connect-codepipeline-with-github" {
  value = [
  "Step1: Open Pipeline settings in AWS Console and Complete the Pending Github Connection",
  "Step2: Add the above CNAME Record in you domain NameServer Records",
  "Step3: Depending on your Domain provider Certificate validation can take few minutes to few days after verification just again run the terraform apply to set up your certificate with Cloudfront.",
  ]
}


output "certificate-cname-records" {
  description = "Add these records in your domain nameserver"
  value = aws_acm_certificate.website-certificate.status == "PENDING_VALIDATION" ? [
    for dvo in aws_acm_certificate.website-certificate.domain_validation_options :   
    <<EOT
    Record No.1 for ${dvo.domain_name}: ${dvo.resource_record_name} => ${dvo.resource_record_value}
    Record No.2 : www => ${aws_cloudfront_distribution.s3-distribution.domain_name}
    EOT
  ] : ["Certificate Attached Successfully"]
}
