terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.36.0"
    }
  }
}

provider "aws" {
  region = "me-central-1"
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}
