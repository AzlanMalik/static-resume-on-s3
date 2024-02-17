output "cert-cname_record" {
  description = "Add this record in your domain nameserver"
  value = { for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
  } }
}

output "codepipeline-github-connect" {
  value = "Open Pipeline settings in AWS Console and Complete the Pending Github Connection"
}


