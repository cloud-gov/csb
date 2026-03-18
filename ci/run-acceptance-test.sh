#!/bin/bash

set -euxo pipefail

. src/ci/ci-utils.sh

TEST_APP="ses-acceptance-test-$TEST_NAME-app"
SERVICE_NAME="ses-acceptance-test-$TEST_NAME"
APP_DIRECTORY="src/brokerpaks/aws-ses/client/"

# Log in to CF
login

# Delete existing app
cf delete -f "$TEST_APP"

# Clean up existing service if present
if cf service "$SERVICE_NAME"; then
  cf delete-service -f "$SERVICE_NAME"
  wait_for_deletion "$SERVICE_NAME"
fi

# change into the directory and push the app without starting it.
pushd $APP_DIRECTORY
cf push "$TEST_APP" -f manifest.yml

ENABLE_FEEDBACK_NOTIFICATIONS=${ENABLE_FEEDBACK_NOTIFICATIONS:-"false"}

# Create service
if [[ "$ENABLE_FEEDBACK_NOTIFICATIONS" == "true" ]]; then
  cf create-service aws-ses "$SERVICE_PLAN" "$SERVICE_NAME" -c '{"admin_email": "'"$ADMIN_EMAIL"'", "enable_feedback_notifications": true}'
else
  cf create-service aws-ses "$SERVICE_PLAN" "$SERVICE_NAME" -c '{"admin_email": "'"$ADMIN_EMAIL"'"}'
fi

wait_for_service_instance "$SERVICE_NAME"

wait_for_service_bindable "$TEST_APP" "$SERVICE_NAME"

# Clean up app and service
cf delete-service -f "$SERVICE_NAME"
wait_for_deletion "$SERVICE_NAME"
