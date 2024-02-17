variable "domain-name" {
  description = "your website domain name"
}

variable "access-token" {
  description = "github access token for codebulid"
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
