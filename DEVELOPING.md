# Developing the Cloud Service Broker

## Prerequisites

Install the Cloud Service Broker:

```shell
git clone https://github.com/cloudfoundry/cloud-service-broker
cd cloud-service-broker
go install
```

## Testing the brokerpak build

Copy `secrets.env.example` to `secrets.env` and update the missing values.

To do a one-time build of the broker:

```shell
make build
```

To watch local files and re-build the broker as they change:

```shell
make watch
```
