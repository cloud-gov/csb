// Resources default to the first provider, govcloud.
provider "aws" {
  alias      = "govcloud"
  access_key = var.aws_access_key_id_govcloud
  secret_key = var.aws_secret_access_key_govcloud
  region     = var.aws_region_govcloud
  # FIPS endpoints are used by default in GovCloud.
}

# Cloud.gov manages DNS in a commercial AWS account, but all other resources
# in a GovCloud account. This necessitates two providers, one for each partition.
# See README.md for more.
provider "aws" {
  alias             = "commercial"
  access_key        = var.aws_access_key_id_commercial
  secret_key        = var.aws_secret_access_key_commercial
  region            = var.aws_region_commercial
  use_fips_endpoint = true
}
