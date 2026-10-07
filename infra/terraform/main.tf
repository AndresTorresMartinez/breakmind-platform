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

module "github_oidc" {
  source = "./modules/github-oidc"
  repo   = "AndresTorresMartinez@19475858/breakmind-platform@1365002336"
}

output "github_oidc_role_arn" {
  value = module.github_oidc.role_arn
}