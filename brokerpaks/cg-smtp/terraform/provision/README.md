# How to iterate on the provisioning code

You can develop and test the Terraform code for provisioning in isolation from
the broker context here.

1. Copy `terraform.tfvars-template` to `terraform.tfvars`, then edit the content
   appropriately. In particular, customize the `instance` and `subdomain`
   parameters to avoid collisions in the target AWS account!
1. Set these three environment variables:

   - AWS_ACCESS_KEY_ID
   - AWS_SECRET_ACCESS_KEY
   - AWS_DEFAULT_REGION

1. In order to have a development environment consistent with other
   collaborators, we use a special Docker image with the exact CLI binaries we
   want for testing. Doing so will avoid [discrepancies we've noted between development under OS X and W10](https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1262#issuecomment-932792757).

   First, build the image:

   ```bash
   docker build -t smtp-provision:latest .
   ```

1. Then, start a shell inside a container based on this image. The parameters
   here carry some of your environment variables into that shell, and ensure
   that you'll have permission to remove any files that get created.

   ```bash
   $ docker run -v `pwd`:`pwd` -w `pwd` -e HOME=`pwd` --user $(id -u):$(id -g) -e TERM -it --rm -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID -e AWS_DEFAULT_REGION smtp-provision:latest

   [within the container]
   terraform init
   terraform apply -auto-approve
   [tinker in your editor, run terraform apply, inspect the cluster, repeat]
   terraform destroy -auto-approve
   exit
   ```

# AWS GovCloud and Commercial

Cloud.gov manages most resources in AWS GovCloud, but uses AWS Commercial to manage DNS with Route53. Since AWS IAM users [cannot have cross-partition permissions](https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html), the brokerpak requires two sets of credentials and two providers to create all necessary resources.
