terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.10"
  backend "s3" {
    bucket       = "breakmind-platform-state"
    key          = "staging/breakmind-base.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}
