locals {
  space_name        = try(var.context.space_name, "")
  organization_name = try(var.context.organization_name, "")
  space_guid        = try(var.context.space_guid, "")
  organization_guid = try(var.context.organization_guid, "")
}

provider "aws" {
  access_key = var.aws_access_key_id_govcloud
  secret_key = var.aws_secret_access_key_govcloud
  region     = var.aws_region_govcloud

  default_tags {
    tags = {
      "broker"                = "Cloud Service Broker"
      "client"                = "Cloud Foundry"
      "environment"           = "local" # todo, parameterize at CSB level
      "Instance GUID"         = var.instance_id
      "Organization GUID"     = local.organization_guid
      "Organization name"     = local.organization_name
      "Space name"            = local.space_name
      "Space GUID"            = local.space_guid
      "Service offering name" = var.service_offering_name
      "Service plan name"     = var.service_plan_name
    }
  }
}
