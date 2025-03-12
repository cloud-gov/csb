locals {
  helper_route = "services.${var.docproxy_domain}"
}

resource "cloudfoundry_app" "helper" {
  name       = "csb-helper"
  org_name   = var.org_name
  space_name = var.space_name

  docker_image = "${var.helper_docker_image_name}${var.helper_docker_image_version}"
  docker_credentials = {
    "username" = var.ecr_access_key_id
    "password" = var.ecr_secret_access_key
  }

  command   = "/app/helper"
  instances = var.helper_instances
  memory    = "128M"

  environment = {
    "AWS_USE_FIPS_ENDPOINT" = true
    "AWS_DEFAULT_REGION"    = var.aws_region_govcloud
    "AWS_ACCESS_KEY_ID"     = var.helper_aws_access_key_id
    "AWS_SECRET_ACCESS_KEY" = var.helper_aws_secret_access_key

    "BROKER_URL"                         = "https://${local.csb_route}"
    "CG_PLATFORM_NOTIFICATION_TOPIC_ARN" = var.email_notification_topic_arn
    "HOST"                               = local.helper_route
  }

  routes = [{
    route = local.helper_route
  }]

  no_route = var.no_route
}

data "cloudfoundry_service_plans" "external_domain" {
  service_offering_name = "external-domain"
  name                  = "domain"
  service_broker_name   = "external-domain-broker"
}

resource "cloudfoundry_service_instance" "docproxy_external_domain" {
  name  = "docproxy-domain"
  space = data.cloudfoundry_space.brokers.id
  type  = "managed"

  service_plan = data.cloudfoundry_service_plans.external_domain.service_plans[0].id

  parameters = jsonencode({
    domains = [local.helper_route]
  })
}

resource "aws_sns_topic_subscription" "platform_ses_notifications" {
  endpoint  = "https://${local.helper_route}/brokerpaks/ses/reputation-alarm"
  protocol  = "https"
  topic_arn = var.email_notification_topic_arn
  filter_policy = jsonencode({
    "AlarmName" : [
      { "prefix" : "SES-BounceRate-Critical-Identity-" },
      { "prefix" : "SES-ComplaintRate-Critical-Identity-" }
    ]
  })
  filter_policy_scope = "MessageBody"
}
