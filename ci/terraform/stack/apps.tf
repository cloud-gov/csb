module "csb" {
  source = "../module"

  cloud_gov_environment = var.iaas_stack_name

  rds_host     = data.terraform_remote_state.iaas.outputs.csb.rds.host
  rds_port     = data.terraform_remote_state.iaas.outputs.csb.rds.port
  rds_name     = data.terraform_remote_state.iaas.outputs.csb.rds.name
  rds_username = data.terraform_remote_state.iaas.outputs.csb.rds.username
  rds_password = data.terraform_remote_state.iaas.outputs.csb.rds.password

  ecr_access_key_id                = data.terraform_remote_state.iaas.outputs.csb.iam.ecr.access_key_id_curr
  ecr_secret_access_key            = data.terraform_remote_state.iaas.outputs.csb.iam.ecr.secret_access_key_curr
  instances                        = 1
  aws_ses_default_zone             = var.csb_aws_ses_default_zone
  aws_access_key_id_govcloud       = data.terraform_remote_state.iaas.outputs.csb.iam.csb.access_key_id_curr
  aws_secret_access_key_govcloud   = data.terraform_remote_state.iaas.outputs.csb.iam.csb.secret_access_key_curr
  aws_region_govcloud              = var.csb_aws_region_govcloud
  aws_access_key_id_commercial     = data.terraform_remote_state.external.outputs.csb.broker_user.access_key_id_curr
  aws_secret_access_key_commercial = data.terraform_remote_state.external.outputs.csb.broker_user.secret_access_key_curr
  aws_region_commercial            = var.csb_aws_region_commercial

  helper_aws_access_key_id     = data.terraform_remote_state.iaas.outputs.csb.iam.csb_helper.access_key_id_curr
  helper_aws_secret_access_key = data.terraform_remote_state.iaas.outputs.csb.iam.csb_helper.secret_access_key_curr

  email_notification_topic_arn = data.terraform_remote_state.iaas.outputs.csb.notification_topics.email_notification_topic_arn
  slack_notification_topic_arn = data.terraform_remote_state.iaas.outputs.csb.notification_topics.slack_notification_topic_arn

  org_name                     = var.csb_org_name
  space_name                   = var.csb_space_name
  docker_image_name            = var.csb_docker_image_name
  docker_image_version         = var.csb_docker_image_version
  broker_route_domain          = var.csb_broker_route_domain
  enable_service_access_global = var.csb_enable_service_access_global
  enable_service_access_orgs   = var.csb_enable_service_access_orgs

  docproxy_domain             = var.csb_docproxy_domain
  helper_instances            = var.csb_helper_instances
  helper_docker_image_name    = var.csb_helper_docker_image_name
  helper_docker_image_version = var.csb_helper_docker_image_version
}
