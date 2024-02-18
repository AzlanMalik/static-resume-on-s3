 /* -------------------------------------------------------------------------- */
 /*                        CODEBUILD IAM ROLE & POLICIES                       */
 /* -------------------------------------------------------------------------- */
data "aws_iam_policy_document" "codebulid-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "codebuild-iam-role" {
  name               = "${var.project-name}-codebulid-role"
  assume_role_policy = data.aws_iam_policy_document.codebulid-policy.json
}

/* -------------------------------------------------------------------------- */
/*        ATTACHING BUCKET POLICY TO CODEBULID AND CODPIPELINE                */
/* -------------------------------------------------------------------------- */


resource "aws_iam_policy_attachment" "bucket-attach-to-codepipeline" {
  name = "bucket-attach-to-codepipeline"
  roles = [aws_iam_role.codebuild-iam-role.name,aws_iam_role.codepipeline-iam-role.name]
  policy_arn = aws_iam_policy.codepipeline-bucket-policy.arn
}


resource "aws_iam_policy" "codepipeline-bucket-policy" {
  name        = "codepipeline-bucket-policy"
  description = "${var.project-name}-codepipeline-bucket-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObjectAcl",
          "s3:PutObject",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${aws_s3_bucket.codepipeline-bucket.bucket}/*"
      },
    ]
  })
}

 /* -------------------------------------------------------------------------- */
 /*                      CODEPIPELINE IAM ROLE & POLICIES                      */
 /* -------------------------------------------------------------------------- */
resource "aws_iam_role" "codepipeline-iam-role" {
  name               = "${var.project-name}-codepipeline-iam-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline-assume-policy.json
}


data "aws_iam_policy_document" "codepipeline-assume-policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy_attachment" "codepipeline-policy-attach" {
  name = "codepipeline-policy-attach"
  roles = [aws_iam_role.codepipeline-iam-role.name]
  policy_arn = aws_iam_policy.codepipeline-policy.arn
}

resource "aws_iam_policy" "codepipeline-policy" {
  name        = "codepipeline-policy"
  description = "${var.project-name}-codepipeline-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:PutObject"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${aws_s3_bucket.website-bucket.bucket}/*"
      },
      {
        Action = [
          "codestar-connections:UseConnection"
        ]
        Effect   = "Allow"
        Resource = "${aws_codestarconnections_connection.website-codestar-connection.arn}"
      },
      {
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
        ]
        Effect   = "Allow"
        Resource = "${aws_codebuild_project.website-codebuild.arn}"
      },
    ]
  })
}
 
