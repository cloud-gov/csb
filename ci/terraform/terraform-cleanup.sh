#!/usr/bin/env bash
set -euxo pipefail

# The CloudFoundry terraform provider has two issues that affect this repo: First, CloudFoundry applications that are updated do not always fully restage, and second, it has no resource for enabling service plan visibility. This script restages the applications manually and enables service plan visibility.
# Issue for app restaging: https://github.com/cloudfoundry/terraform-provider-cloudfoundry/issues/127
# Issue for service plan visibility: https://github.com/cloudfoundry/terraform-provider-cloudfoundry/issues/96

# Load values from state file
ORG=$(jq  -r '.outputs.org_name.value' terraform-state/terraform.tfstate)
SPACE=$(jq  -r '.outputs.space_name.value' terraform-state/terraform.tfstate)
CSB=$(jq  -r '.outputs.app_name.value' terraform-state/terraform.tfstate)
CSB_HELPER=$(jq  -r '.outputs.helper_app_name.value' terraform-state/terraform.tfstate)

cf api $CF_API_URL
(set +x; cf auth $CF_CLIENT_ID $CF_CLIENT_SECRET --client-credentials)

cf target -o $ORG -s $SPACE
cf restage $CSB --strategy rolling
cf restage $CSB_HELPER --strategy rolling

if $NO_ROUTE; then
	echo "NO_ROUTE was specified. Service access will not be enabled."
	exit 0
fi

# If list of orgs is empty, register cluster-wide.
# If the list has contents, register in each org.
if [[ -z "$REGISTER_ORGS" ]]; then
	# If no orgs are specified, register cluster-wide.
	cf enable-service-access aws-ses -b $CSB
else
	# If orgs are specified, enable service access for each one.
	echo "$REGISTER_ORGS" | xargs -I% cf enable-service-access aws-ses -b $CSB -o %
fi
