module "ses_broker_test_user" {
  source = "../module/test-user"

  org_name              = var.ses_broker_tests_org_name
  space_name            = var.ses_broker_tests_space_name
  deployer_service_name = var.ses_broker_tests_deployer_service_name
}
