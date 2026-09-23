#!/bin/bash

login() {
  cf api "$CF_API_URL"
  set +x

  if [[ -z "$CF_USERNAME" && -z "$CF_PASSWORD" ]]; then
    if [[ -n "$CF_USER_SERVICE_NAME" && -n "$CF_USER_SERVICE_KEY_NAME" ]]; then
      CF_USER_SERVICE_KEY_GUID=$(cf service-key "$CF_USER_SERVICE_NAME" "$CF_USER_SERVICE_KEY_NAME" --guid)
      CF_USERNAME=$(cf curl "/v3/service_credential_bindings/$CF_USER_SERVICE_KEY_GUID/details" | jq -r '.credentials.username')
      CF_PASSWORD=$(cf curl "/v3/service_credential_bindings/$CF_USER_SERVICE_KEY_GUID/details" | jq -r '.credentials.password')
    fi
  fi

  if [[ -z "$CF_USERNAME" && -z "$CF_PASSWORD" ]]; then
    echo "no credentials provided for login"
    exit 1
  fi

  cf auth "$CF_USERNAME" "$CF_PASSWORD"

  set -x
  cf target -o "$CF_ORGANIZATION" -s "$CF_SPACE"
}

# Function for waiting on a service instance to finish being processed.
function wait_for_service_instance {
  local service_name=$1
  local guid
  guid=$(cf service --guid "$service_name")
  local status
  status=$(cf curl "/v3/service_instances/$guid" | jq -r '.last_operation.state')

  while [ "$status" == "in progress" ]; do
    sleep 60
    status=$(cf curl "/v3/service_instances/$guid" | jq -r '.last_operation.state')
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

function wait_for_service_bindable {
  args=("$1" "$2")
  params=${3:-""}
  if [[ -n "$params" ]]; then
    args+=(-c "$params")
  fi

  while true; do
    if out=$(cf bind-service "${args[@]}"); then
      break
    fi
    if [[ $out =~ "Instance not available yet" ]]; then
      echo "${out}"
    fi
    sleep 60
  done
}
