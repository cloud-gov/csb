#!/bin/bash
set -eo pipefail

if [ "$#" -lt 2 ]; then
  printf "Usage:\n\n\t\$./up.sh recipient-email@gsa.gov /path/to/workdir\n\n"
  exit 1
fi

recipient=$1
workdir=$2

csb=cloud-service-broker

# Instance IDs must be unique, so generate a new one
instanceid=$(uuidgen | tr "[A-Z]" "[a-z]")
echo "Instance ID: $instanceid"

# Start provisioning
$csb client provision --config clientconfig.yml --planid 35ffb84b-a898-442e-b5f9-0a6a5229827d --serviceid 260f2ead-b9e9-48b5-9a01-6e3097208ad7 --instanceid $instanceid --params "{\"dmarc_report_aggregate_recipients\": \"mailto:${recipient}\", \"dmarc_report_failure_recipients\": \"${recipient}\"}"

# Wait on provisioning to finish
state=""
while [[ "$state" != "succeeded" ]]; do
	sleep 10
	state=$($csb client --config clientconfig.yml last --instanceid $instanceid | jq -r '.response.state')
	echo "State: $state"
done

touch "$workdir/instances.txt"
echo $instanceid >> "$workdir/instances.txt"

# Let the broker settle
sleep 1

# Binding IDs must be unique, so generate a new one
bindingid=$(uuidgen | tr "[A-Z]" "[a-z]")
echo "Binding ID: $bindingid"
touch "$workdir/bindings.txt"
echo "$instanceid $bindingid" >> "$workdir/bindings.txt"

# Update smtp-client with new credentials
$csb client bind --config clientconfig.yml --planid 35ffb84b-a898-442e-b5f9-0a6a5229827d --serviceid 260f2ead-b9e9-48b5-9a01-6e3097208ad7 --instanceid $instanceid --bindingid $bindingid | jq '.response.credentials' > "$workdir/credentials.json"

echo "Done. Credentials saved to credentials.json for use with the client. GUIDs saved to instances.txt and bindings.txt. Deprovision later with down.sh."
