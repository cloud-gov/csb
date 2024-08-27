provider "aws" {
  access_key = var.aws_access_key_id_govcloud
  secret_key = var.aws_secret_access_key_govcloud
  region     = var.aws_region_govcloud

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
