# Developing the Cloud Service Broker (CSB)

## Prerequisites

Install the Cloud Service Broker:

```shell
git clone https://github.com/cloudfoundry/cloud-service-broker
cd cloud-service-broker
go install
```

## Testing the CSB build

Copy `secrets.env.example` to `secrets.env` and update the missing values.

To do a one-time build of the CSB:

```shell
make build
```

To watch local files and re-build the CSB as they change:

```shell
make watch
```

## Testing Terraform code

> WARNING: Following these steps will actually provision AWS resources

## SES brokerpak

1. Change to the directory of the terraform operation you want to test:

    ```shell
    cd brokerpaks/aws-ses/terraform/provision
    ```

1. Run `terraform init`
1. Copy `terraform.tfvars-template` to `terraform.tfvars` and add missing values
1. Run `terraform plan` and `terraform apply` to verify whether the Terraform code works as expected

## Testing brokerpaks locally

You can run the Cloud Service Broker (CSB) locally to validate that your brokerpak works
as expected when packaged into the CSB.

### Testing SES brokerpak

> WARNING: Following these steps will actually provision AWS resources

1. Copy `secrets.env.example` to `secrets.env` and update the missing values
1. Run the CSB locally in "watch" mode, which will rebuild and restart the CSB as you change files:

    ```shell
    make watch
    ```

1. Create `brokerpaks/aws-ses/client/clientconfig.yml`:

    ```yaml
    api:
        user: <broker-username>
        password: <broker-password>
        port: 8081
    ```

    where

    - `broker-username` matches `SECURITY_USER_NAME` from `secrets.env`
    - `broker-password` matches `SECURITY_USER_PASSWORD` from `secrets.env`

1. From the `brokerpaks/aws-ses/client` directory, run `up.sh`:

    ```shell
    cd brokerpaks/aws-ses/client
    ./bin/up.sh your-email@agency.gov .
    ```

    You can optionally specify additional parameters to the service creation like so:

    ```shell
    /bin/up.sh your-email@agency.gov . '{"enable_feedback_notifications": true}'
    ```

1. Verify that the `up.sh` scripts returns without an error and that `brokerpaks/aws-ses/client/credentials.json` contains bound credentials for the created service
1. Deprovision the created resources:

    ```shell
    ./bin/down.sh .
    ```

1. Verify that the `down.sh` completes successfully
