#!/bin/bash

set -eu

# untar the contents of the resource; delete the tarball; remove the version file
cd terraform-plugin-cache
# todo get the actual name so I can re-compress it later
tar xzf terraform-plugin-cache/*.tar.gz
cd ..

# Use client credentials in CF_CLIENT_ID and CF_CLIENT_SECRET to fetch a token
API_RESPONSE=$(curl -s $CF_API_URL/v2/info)
TOKEN_ENDPOINT=$(echo ${API_RESPONSE} | jq -r '.token_endpoint // empty')

if [ -z "${TOKEN_ENDPOINT}" ]; then
  echo "API didn't return a token endpoint: ${API_RESPONSE}"
  exit 99;
fi

UAA_RESPONSE=$(curl -s \
  -X POST \
  -d "grant_type=client_credentials&response_type=token&client_id=${CF_CLIENT_ID}&client_secret=${CF_CLIENT_SECRET}" \
  ${TOKEN_ENDPOINT}/oauth/token
)
export CF_TOKEN=$(echo ${UAA_RESPONSE} | jq -r -r '.access_token // empty')

if [ -z "${CF_TOKEN}" ]; then
  echo "UAA did not return a token: ${UAA_RESPONSE}"
  exit 99;
fi

# Execute the terraform action, the cloudfoundry provider will use CF_API and CF_TOKEN to authenticate
./pipeline-tasks/terraform-apply.sh
exit 1 # crash the container so I can debug the plugin cache

# re-zip the tarball; delete the rest of the files
