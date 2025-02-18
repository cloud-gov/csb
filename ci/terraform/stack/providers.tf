terraform {
  backend "s3" {
  }
}

provider "aws" {
  access_key = data.terraform_remote_state.iaas.outputs.csb.iam.concourse.access_key_id_curr
  secret_key = data.terraform_remote_state.iaas.outputs.csb.iam.concourse.secret_access_key_curr
  region     = var.csb_aws_region_govcloud
}

provider "cloudfoundry" {
}
