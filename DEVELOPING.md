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

## Testing Terraform code

## SES brokerpak

1. Change to the directory of the terraform operation you want to test:

    ```shell
    cd brokerpaks/aws-ses/terraform/provision
    ```

1. Run `terraform init`
1. Copy `terraform.tfvars-template` to `terraform.tfvars` and add missing values
1. Run `terraform plan` and `terraform apply` to verify whether the Terraform code works as expected
