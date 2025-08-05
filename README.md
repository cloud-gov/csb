# Cloud Service Broker

This repo contains configuration, including brokerpaks, for the cloud.gov deployment of the [Cloud Service Broker](https://github.com/cloudfoundry/cloud-service-broker).

## Troubleshooting

> error getting new instance details: error creating TF state: error unmarshalling JSON state: json: cannot unmarshal array into Go struct field .outputs.type of type string

The brokerpak outputs cannot be of `list` or `map` types because the CSB code expects a simple string name for all output types, and those container types are encoded in the statefile as `["container", "type"]`, e.g. `["list", "string"]`. Make the output a simpler type, like `string`.

## Related projects

- https://github.com/GSA-TTS/datagov-brokerpak-smtp
- https://github.com/GSA/ttsnotify-brokerpak-sms

## Credits

- AWS Architecture icons are sourced from https://aws.amazon.com/architecture/icons/.
