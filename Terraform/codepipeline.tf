/* -------------------------------------------------------------------------- */
/*                                  CODEBULID                                 */
/* -------------------------------------------------------------------------- */
resource "aws_codebuild_project" "website-codebuild" {
  name           = "${var.project-name}-bulid"
  description    = "${var.project-name} Codebuild"
  build_timeout  = 5
  queued_timeout = 5

  service_role = aws_iam_role.codebuild-iam-role.arn

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
resource "aws_codepipeline" "website-codepipeline" {
  name     = "${var.project-name}-pipeline"
  role_arn = aws_iam_role.codepipeline-iam-role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline-bucket.bucket
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
        ConnectionArn    = aws_codestarconnections_connection.website-codestar-connection.arn
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
        ProjectName = aws_codebuild_project.website-codebuild.name
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
        BucketName = aws_s3_bucket.website-bucket.bucket
        Extract    = true
      }
    }
  }

}


/* --------------------------- CODESTAR CONNECTION -------------------------- */
resource "aws_codestarconnections_connection" "website-codestar-connection" {
  name          = "${var.project-name}-connection"
  provider_type = "GitHub"
}
