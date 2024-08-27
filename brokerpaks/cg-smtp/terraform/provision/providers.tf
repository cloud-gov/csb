// Resources without a `provider` attribute default to this provider, which targets govcloud.
provider "aws" {
  access_key = var.aws_access_key_id_govcloud
  secret_key = var.aws_secret_access_key_govcloud
  region     = var.aws_region_govcloud
  # FIPS endpoints are used by default in GovCloud.

  default_tags {
    tags = {
      "broker"                = "Cloud Service Broker"
      "client"                = "Cloud Foundry"
      "environment"           = "development" # todo, parameterize at CSB level
      "Instance GUID"         = var.instance_name
      "Organization GUID"     = "" # todo, see https://github.com/cloud-gov/product/issues/3107#issuecomment-2312442514
      "Organization name"     = "" # todo
      "Service offering name" = "" # todo
      "Service plan name"     = "" # todo
    }
  }
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

  default_tags {
    tags = {
      "broker"                = "Cloud Service Broker"
      "client"                = "Cloud Foundry"
      "environment"           = "development" # todo, parameterize at CSB level
      "Instance GUID"         = var.instance_name
      "Organization GUID"     = "" # todo, see https://github.com/cloud-gov/product/issues/3107#issuecomment-2312442514
      "Organization name"     = "" # todo
      "Service offering name" = "" # todo
      "Service plan name"     = "" # todo
    }
  }
}
