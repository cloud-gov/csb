#!/bin/bash

login() {
  cf api "$CF_API_URL"
  set +x
  cf auth "$CF_USERNAME" "$CF_PASSWORD"
  set -x
  cf target -o "$CF_ORGANIZATION" -s "$CF_SPACE"
}

# Function for waiting on a service instance to finish being processed.
wait_for_service_instance() {
  local service_name=$1
  local guid
  guid=$(cf service --guid "$service_name")
  local status
  status=$(cf curl "/v2/service_instances/$guid" | jq -r '.entity.last_operation.state')

  while [ "$status" == "in progress" ]; do
    sleep 60
    status=$(cf curl "/v2/service_instances/$guid" | jq -r '.entity.last_operation.state')
  done

  if [ "$status" == "failed" ]; then
    echo "failed to create service instance"
    cf service "$service_name"
    exit 1
  fi
}

function wait_for_deletion {
  while true; do
    if ! cf service "$1"; then
      break
    fi
    echo "Waiting for $1 to be deleted"
    sleep 60
  done
}
