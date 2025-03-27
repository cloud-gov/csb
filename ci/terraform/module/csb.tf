locals {
  csb_route = "csb.${var.broker_route_domain}"
}

resource "random_password" "csb_app_password" {
  length      = 32
  special     = false
  min_special = 0
  min_upper   = 5
  min_numeric = 5
  min_lower   = 5
}

resource "cloudfoundry_app" "csb" {
  name       = "csb"
  org_name   = var.org_name
  space_name = var.space_name

  docker_image = "${var.docker_image_name}${var.docker_image_version}"
  docker_credentials = {
    "username" = var.ecr_access_key_id
    "password" = var.ecr_secret_access_key
  }

  command    = "/app/csb serve"
  instances  = var.instances
  memory     = "1G"
  disk_quota = "7G"

  environment = {
    # General broker configuration.
    # Configuration spec: https://github.com/cloudfoundry/cloud-service-broker/blob/main/docs/configuration.md
    BROKERPAK_UPDATES_ENABLED  = true
    DB_HOST                    = var.rds_host
    DB_NAME                    = var.rds_name
    DB_PASSWORD                = var.rds_password
    DB_PORT                    = var.rds_port
    DB_TLS                     = true
    DB_USERNAME                = var.rds_name
    SECURITY_USER_NAME         = "broker"
    SECURITY_USER_PASSWORD     = random_password.csb_app_password.result
    TERRAFORM_UPGRADES_ENABLED = true

    # Access keys for managing resources provisioned by brokerpaks
    AWS_USE_FIPS_ENDPOINT            = true
    AWS_ACCESS_KEY_ID_GOVCLOUD       = var.aws_access_key_id_govcloud
    AWS_SECRET_ACCESS_KEY_GOVCLOUD   = var.aws_secret_access_key_govcloud
    AWS_REGION_GOVCLOUD              = var.aws_region_govcloud
    AWS_ACCESS_KEY_ID_COMMERCIAL     = var.aws_access_key_id_commercial
    AWS_SECRET_ACCESS_KEY_COMMERCIAL = var.aws_secret_access_key_commercial
    AWS_REGION_COMMERCIAL            = var.aws_region_commercial

    # Other values that are used by convention by all brokerpaks
    CLOUD_GOV_ENVIRONMENT                  = var.cloud_gov_environment
    CLOUD_GOV_EMAIL_NOTIFICATION_TOPIC_ARN = var.email_notification_topic_arn
    CLOUD_GOV_SLACK_NOTIFICATION_TOPIC_ARN = var.slack_notification_topic_arn

    # Brokerpak-specific variables
    BP_AWS_SES_DEFAULT_ZONE = var.aws_ses_default_zone
  }

  readiness_health_check_type          = "http"
  readiness_health_check_http_endpoint = "/ready"

  routes = var.no_route ? null : [{
    route = local.csb_route
  }]

  no_route = var.no_route ? var.no_route : null
}

resource "cloudfoundry_service_broker" "csb" {
  name     = "csb"
  password = random_password.csb_app_password.result
  url      = "https://${local.csb_route}"
  username = "broker"

  depends_on = [cloudfoundry_app.csb]
}

data "cloudfoundry_service_plans" "csb" {
  service_broker_name = "csb"

  depends_on = [cloudfoundry_app.csb]
}

locals {
  plans = toset(data.cloudfoundry_service_plans.csb.service_plans[*].id)
}

resource "cloudfoundry_service_plan_visibility" "csb" {
  for_each     = local.plans
  service_plan = each.key

  type          = "organization"
  organizations = [var.org_name]

  depends_on = [cloudfoundry_service_broker.csb]
}
