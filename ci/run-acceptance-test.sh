#!/bin/bash

set -euxo pipefail

. csb-source/ci/ci-utils.sh

SERVICE_NAME="ses-acceptance-test-$TEST_NAME"

# Log in to CF
login

# Clean up existing service if present
if cf service "$SERVICE_NAME"; then
  cf delete-service -f "$SERVICE_NAME"
  wait_for_deletion "$SERVICE_NAME"
fi

# Create service
cf create-service aws-ses "$SERVICE_PLAN" "$SERVICE_NAME"

# Clean up app and service
cf delete-service -f "$SERVICE_NAME"
wait_for_deletion "$SERVICE_NAME"
