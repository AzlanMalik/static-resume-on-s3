/* -------------------------------------------------------------------------- */
/*                           Creating the S3 Bucket                           */
/* -------------------------------------------------------------------------- */
resource "aws_s3_bucket" "website-bucket" {
  bucket = var.domain-name

  force_destroy = true
}

/* ---------------------- Enabling Static Hosting on S3 --------------------- */
resource "aws_s3_bucket_website_configuration" "enable-hosting" {
  bucket = aws_s3_bucket.website-bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

/* ---------- Enabling Public Access on S3 Bucket and adding Policy --------- */
resource "aws_s3_bucket_public_access_block" "allow-public-access" {
  bucket = aws_s3_bucket.website-bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "allow-access-policy" {
  bucket = aws_s3_bucket.website-bucket.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Statement1",
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "s3:GetObject",
        "Resource" : "arn:aws:s3:::${aws_s3_bucket.website-bucket.bucket}/*"
      }
    ]
  })

}

/* -------------------------------------------------------------------------- */
/*                             CODEPIPELINE BUCKET                            */
/* -------------------------------------------------------------------------- */
resource "aws_s3_bucket" "codepipeline-bucket" {
  bucket = var.codepipeline-bucket

  force_destroy = true
}
