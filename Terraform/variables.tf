variable "aws-region" {
  description = "AWS region where you want to deploy all of the services"
}

variable "project-name" {
  description = "Any name you want to mention on AWS resource"
}

variable "domain-name" {
  description = "your website domain name"
}

variable "github-repo" {
  description = "github repository url"
}

variable "git-owner" {
  description = "github repo owner username"
}

variable "git-repo" {
  description = "github repository name"
}

variable "codepipeline-bucket" {
  description = "bucket name for codepipeline artifacts"
}
