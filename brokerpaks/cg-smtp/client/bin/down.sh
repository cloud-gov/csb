#!/bin/bash
set -eo pipefail

# Work around the broker not having a command like `csb client list` by tracking the
# instances and bindings we've created.

if [ "$#" -lt 1 ]; then
  printf "Usage:\n\n\t\$./down.sh /path/to/workdir\n\nWorking directory must match the directory passed to up.sh."
  exit 1
fi

workdir=$1

cat "${workdir}/bindings.txt" | xargs -n 2 bash -c 'cloud-service-broker client unbind --config clientconfig.yml --planid 35ffb84b-a898-442e-b5f9-0a6a5229827d --serviceid 260f2ead-b9e9-48b5-9a01-6e3097208ad7 --instanceid $1 --bindingid $2' -
echo "\n\n$(date)" >> bindings.txt.history
cat ${workdir}/bindings.txt >> ${workdir}/bindings.txt.history
rm ${workdir}/bindings.txt

cat "${workdir}/instances.txt" | xargs -I % cloud-service-broker client deprovision --config clientconfig.yml --planid 35ffb84b-a898-442e-b5f9-0a6a5229827d --serviceid 260f2ead-b9e9-48b5-9a01-6e3097208ad7 --instanceid %
echo "\n$(date)" >> instances.txt.history
cat ${workdir}/instances.txt >> ${workdir}/instances.txt.history
rm ${workdir}/instances.txt

echo "Done. instances.txt and bindings.txt cleared. History recorded in instances.txt.history and bindings.txt.history."

