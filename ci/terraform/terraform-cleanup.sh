#!/usr/bin/env bash
set -euxo pipefail

# The CloudFoundry terraform provider has two issues that affect this repo: First, CloudFoundry applications that are updated do not always fully restage, and second, it has no resource for enabling service plan visibility. This script restages the applications manually and enables service plan visibility.
# Issue for app restaging: https://github.com/cloudfoundry/terraform-provider-cloudfoundry/issues/127
# Issue for service plan visibility: https://github.com/cloudfoundry/terraform-provider-cloudfoundry/issues/96

# Load values from state file
ORG=$(jq -f terraform-state/terraform.tfstate -r '.outputs.org_name.value')
SPACE=$(jq -f terraform-state/terraform.tfstate -r '.outputs.space_name.value')
CSB=$(jq -f terraform-state/terraform.tfstate -r '.outputs.app_name.value')
CSB_HELPER=$(jq -f terraform-state/terraform.tfstate -r '.outputs.helper_app_name.value')

(set +x; cf auth $CF_CLIENT_ID $CF_CLIENT_SECRET --client-credentials)

cf target $ORG $SPACE
cf restage $CSB --strategy rolling
cf restage $CSB_HELPER --strategy rolling
cf enable-service-access aws-ses -b $CSB -o $ORG # TODO xargs this
