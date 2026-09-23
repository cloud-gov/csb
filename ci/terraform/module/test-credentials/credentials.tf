data "cloudfoundry_org" "tests_org" {
  name = var.org_name
}

data "cloudfoundry_space" "space_name" {
  name = var.space_name
  org  = data.cloudfoundry_org.tests_org.id
}

data "cloudfoundry_service_plans" "space_deployer_account_plan" {
  service_offering_name = "cloud-gov-service-account"
  name                  = "space-deployer"
  service_broker_name   = "uaa-credentials-broker"
}

resource "cloudfoundry_service_instance" "test_user" {
  name  = var.deployer_service_name
  space = data.cloudfoundry_space.tests_space.id
  type  = "managed"

  service_plan = data.cloudfoundry_service_plans.space_deployer_account_plan.service_plans[0].id
}

resource "cloudfoundry_service_credential_binding" "test_user_key" {
  type             = "key"
  name             = var.deployer_service_key_name
  service_instance = cloudfoundry_service_instance.test_user.id
}
