terraform {
  required_version = "= 1.13.1"

  required_providers {
    aws = {
      source  = "registry.terraform.io/hashicorp/aws"
      version = "= 5.92.0"
    }
    cloudfoundry = {
      source  = "registry.terraform.io/cloudfoundry/cloudfoundry"
      version = "= 1.4.0"
    }
  }
}

provider "aws" {
  region              = local.dev_config.aws_region
  allowed_account_ids = [local.dev_config.aws_account_id]
  use_fips_endpoint   = true
}

provider "cloudfoundry" {
  skip_ssl_validation = false
}