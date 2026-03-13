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
if [[ "$ENABLE_FEEDBACK_NOTIFICATIONS" == "true" ]]; then
  cf create-service aws-ses "$SERVICE_PLAN" "$SERVICE_NAME" -c '{"admin_email": "'"$ADMIN_EMAIL"'", "enable_feedback_notifications": true}'
else
  cf create-service aws-ses "$SERVICE_PLAN" "$SERVICE_NAME" -c '{"admin_email": "'"$ADMIN_EMAIL"'"}'
fi


# Clean up app and service
cf delete-service -f "$SERVICE_NAME"
wait_for_deletion "$SERVICE_NAME"
