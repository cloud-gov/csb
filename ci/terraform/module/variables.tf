variable "cloud_gov_environment" {
  type        = string
  description = "Like development, staging, or production."
}

# CSB CF Application Configuration

variable "org_name" {
  type        = string
  description = "The name of the Cloud Foundry organization in which the broker will be deployed."
}

variable "space_name" {
  type        = string
  description = "The name of the Cloud Foundry space in which the broker will be deployed."
}

variable "docker_image_name" {
  type        = string
  description = "Full name (but not tag or SHA) of the Docker image the broker will use."
}

variable "docker_image_version" {
  type        = string
  description = "Tag or SHA of the Docker image the broker will use. For example, ':latest' or '@sha256:abc123...'."
  default     = ":latest"
}

variable "ecr_access_key_id" {
  description = "For pulling the CSB image from ECR."
  type        = string
}

variable "ecr_secret_access_key" {
  description = "For pulling the CSB image from ECR."
  sensitive   = true
  type        = string
}

variable "instances" {
  description = "Number of instances of the CSB app to run."
  type        = number
}

variable "broker_route_domain" {
  type        = string
  description = "The domain under which the broker's route will be created. For example, 'fr.cloud.gov'."
}

variable "enable_service_access_global" {
  type        = bool
  default     = false
  description = "Set this to true to enable service access for all CSB service offerings globally in the Foundation. If true, service_access_orgs will be ignored."
}

variable "enable_service_access_orgs" {
  type        = list(string)
  description = "The names of organizations in which service access will be enabled for CSB service offerings. Only used if service_access_global is set to false."
}

# Database credentials

variable "rds_host" {
  type        = string
  description = "Hostname of the RDS instance for the Cloud Service Broker."
}

variable "rds_port" {
  type        = string
  description = "Port of the RDS instance for the Cloud Service Broker."
}

variable "rds_name" {
  type        = string
  description = "Database name within the RDS instance for the Cloud Service Broker."
}

variable "rds_username" {
  type        = string
  description = "Database username of the RDS instance for the Cloud Service Broker."
}

variable "rds_password" {
  type        = string
  sensitive   = true
  description = "Database password of the RDS instance for the Cloud Service Broker."
}

# CSB Configuration

variable "email_notification_topic_arn" {
  type        = string
  description = "ARN of an SNS topic. The CSB will send email alarms to the Cloud.gov team via this topic."
}

variable "slack_notification_topic_arn" {
  type        = string
  description = "ARN of an SNS topic. The CSB will send slack alarms to the Cloud.gov team via this topic."
}

variable "aws_ses_default_zone" {
  type        = string
  description = "When the user does not provide a domain, a subdomain will be created for them under this DNS zone."
}

variable "aws_access_key_id_govcloud" {
  type = string
}

variable "aws_secret_access_key_govcloud" {
  type      = string
  sensitive = true
}

variable "aws_region_govcloud" {
  type = string
}

variable "aws_access_key_id_commercial" {
  type = string
}

variable "aws_secret_access_key_commercial" {
  type      = string
  sensitive = true
}

variable "aws_region_commercial" {
  type = string
}

# CSB helper service configuration

variable "docproxy_domain" {
  type        = string
  description = "The parent domain in CF under which the docproxy will be routed. For example, to serve it on services.fr.cloud.gov, set this to fr.cloud.gov. The subdomain is always 'services'."
}

variable "helper_docker_image_name" {
  type        = string
  description = "Full name (but not tag or SHA) of the Docker image the broker will use."
}

variable "helper_docker_image_version" {
  type        = string
  description = "Tag or SHA of the Docker image the broker will use. For example, ':latest' or '@sha256:abc123...'."
  default     = ":latest"

}

variable "helper_instances" {
  type        = number
  description = "Number of instances of the helper app to run."
}

variable "helper_aws_access_key_id" {
  type = string
}

variable "helper_aws_secret_access_key" {
  type      = string
  sensitive = true
}
