/* -------------------------------------------------------------------------- */
/*                           Creating the S3 Bucket                           */
/* -------------------------------------------------------------------------- */
resource "aws_s3_bucket" "my_bucket" {
  bucket = var.domain-name

  tags = {
    Name = "Static-Website-Bucket"
  }
}

/* ---------------------- Enabling Static Hosting on S3 --------------------- */
resource "aws_s3_bucket_website_configuration" "enable_hosting" {
  bucket = aws_s3_bucket.my_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

/* ---------- Enabling Public Access on S3 Bucket and adding Policy --------- */
resource "aws_s3_bucket_public_access_block" "allow_public_access" {
  bucket = aws_s3_bucket.my_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "allow_access_policy" {
  bucket = aws_s3_bucket.my_bucket.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Statement1",
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "s3:GetObject",
        "Resource" : "arn:aws:s3:::${aws_s3_bucket.my_bucket.bucket}/*"
      }
    ]
  })

}

/* -------------------------------------------------------------------------- */
/*                             SSL/TLS CERTIFICATE                            */
/* -------------------------------------------------------------------------- */
resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain-name
  validation_method = "DNS"
}


/* -------------------------------------------------------------------------- */
/*                                 CLOUDFRONT                                 */
/* -------------------------------------------------------------------------- */
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "example"
  description                       = "Example Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.my_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id                = aws_s3_bucket.my_bucket.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"


  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.my_bucket.id
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
    target_origin_id = aws_s3_bucket.my_bucket.id

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
    target_origin_id = aws_s3_bucket.my_bucket.id

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
    cloudfront_default_certificate = true
  }
}



/* -------------------------------------------------------------------------- */
/*                                  CODEBULID                                 */
/* -------------------------------------------------------------------------- */

resource "aws_codebuild_source_credential" "codebulid-credentials" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = var.access-token
}

resource "aws_codebuild_project" "project-codebuild" {
  name           = "static-resume-bulid"
  description    = "Static Resume Website Codebuild"
  build_timeout  = 5
  queued_timeout = 5

  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  logs_config {
    cloudwatch_logs {
      status = "DISABLED"
    }
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type            = "GITHUB"
    location        = var.github-repo
    git_clone_depth = 1
  }
}


/* -------------------------------------------------------------------------- */
/*                                CODEPIPELINE                                */
/* -------------------------------------------------------------------------- */
resource "aws_codepipeline" "codepipeline" {
  name     = "static-resume-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.example.arn
        FullRepositoryId = "${var.git-owner}/${var.git-repo}"
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.project-codebuild.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy-To-S3"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        BucketName = aws_s3_bucket.my_bucket.bucket
        Extract    = true
      }
    }
  }

}



/* --------------------------- CODEPIPELINE BUCKET -------------------------- */
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = var.codepipeline-bucket
}

resource "aws_s3_bucket_public_access_block" "codepipeline_bucket_pab" {
  bucket = aws_s3_bucket.codepipeline_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


/* --------------------------- CODESTAR CONNECTION -------------------------- */
resource "aws_codestarconnections_connection" "example" {
  name          = "static-resume-connection"
  provider_type = "GitHub"
}







# # Wire the CodePipeline webhook into a GitHub repository.
# resource "github_repository_webhook" "bar" {
#   repository = var.github-repo

#   name = "web"

#   configuration {
#     url          = aws_codepipeline_webhook.bar.url
#     content_type = "json"
#     insecure_ssl = true
#     secret       = local.webhook_secret
#   }

#   events = ["push"]
# }
