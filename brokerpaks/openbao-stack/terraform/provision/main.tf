locals {
  dev_config   = jsondecode(var.dev_config)
  name         = "bao-${var.instance_id}"
  endpoint     = "https://${local.name}.apps.internal:61443"
  db_name      = "${local.name}-db"
  recovery_ref = "${local.dev_config.recovery_prefix}/${var.instance_id}"
  oidc_subject = "${local.dev_config.aws_subject_prefix}${var.instance_id}"
  kms_endpoint = "https://kms-fips.${local.dev_config.aws_region}.amazonaws.com"
  # The connection URL comes from the app's database binding at runtime
  runtime_config = jsonencode({
    api_addr      = local.endpoint
    ui            = false
    disable_mlock = true
    storage       = { postgresql = {} }
    listener = { tcp = {
      address     = "0.0.0.0:8200"
      tls_disable = true
    } }
    seal = { awskms = {
      region     = local.dev_config.aws_region
      kms_key_id = aws_kms_key.seal.arn
      endpoint   = local.kms_endpoint
    } }
    audit = { file = { broker = {
      local = false
      options = {
        file_path = "stdout"
        log_raw   = "false"
      }
    } } }
  })
}

resource "terraform_data" "owner" {
  input = var.instance_id

  lifecycle {
    precondition {
      condition     = var.organization_guid == local.dev_config.org_guid && can(regex("^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$", var.space_guid))
      error_message = "The caller must be in the configured prototype organization and have a platform-supplied space GUID."
    }
    precondition {
      condition     = can(regex("^(/[A-Za-z0-9_.-]+)+$", var.management_credential_ref)) && !startswith(var.management_credential_ref, "${local.dev_config.recovery_prefix}/")
      error_message = "Configure separate SSM paths for broker root and custodian recovery material"
    }
    precondition {
      condition = (
        can(regex("^us-gov-(east|west)-1$", local.dev_config.aws_region)) &&
        can(regex("^[0-9]{12}$", local.dev_config.aws_account_id)) &&
        can(regex("@sha256:[0-9a-f]{64}$", local.dev_config.runtime_image)) &&
        startswith(local.dev_config.parameter_key_id, "arn:aws-us-gov:kms:${local.dev_config.aws_region}:${local.dev_config.aws_account_id}:key/") &&
        can(regex("^(/[A-Za-z0-9_.-]+)+$", local.dev_config.recovery_prefix)) &&
        length(local.dev_config.recovery_pgp_key) > 0 && length(local.dev_config.rds_ca_pem) > 0
      )
      error_message = "Configure the GovCloud dev account, pinned image, and separate recovery custody."
    }

    precondition {
      condition = length(local.dev_config.egress_rules) > 0 && alltrue([
        for rule in local.dev_config.egress_rules :
        contains(["tcp", "udp"], rule.protocol) &&
        can(cidrhost(rule.destination, 0)) &&
        !endswith(rule.destination, "/0") &&
        can(regex("^[0-9]+$", rule.ports))
      ])
      error_message = "Supply explicit egress CIDRs and ports for the runtime space"
    }
  }
}

resource "cloudfoundry_space" "runtime" {
  org       = local.dev_config.org_guid
  name      = local.name
  allow_ssh = false

  depends_on = [terraform_data.owner, terraform_data.root_custody]
}

resource "cloudfoundry_security_group" "runtime" {
  name                     = local.name
  globally_enabled_running = false
  globally_enabled_staging = false
  running_spaces           = [cloudfoundry_space.runtime.id]
  rules = [
    for rule in local.dev_config.egress_rules : {
      protocol    = rule.protocol
      destination = rule.destination
      ports       = rule.ports
    }
  ]
}

resource "cloudfoundry_service_instance" "database" {
  name         = local.db_name
  type         = "managed"
  space        = cloudfoundry_space.runtime.id
  service_plan = local.dev_config.rds_plan_guid
  parameters   = jsonencode({ backup_retention_period = 14 })

  depends_on = [aws_kms_key.seal]
}

resource "aws_kms_key" "seal" {
  description             = "OpenBao seal for ${var.instance_id}"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = { OpenBaoInstance = var.instance_id }

  depends_on = [terraform_data.owner, terraform_data.root_custody]
}

resource "aws_iam_user" "runtime" {
  name          = local.name
  path          = "/cf/openbao/"
  force_destroy = false

  tags = { OpenBaoInstance = var.instance_id }

  depends_on = [terraform_data.owner]
}

resource "aws_iam_access_key" "runtime" {
  user   = aws_iam_user.runtime.name
  status = "Active"

  # A replacement key must exist before CF switches the app's environment.
  # Production rotation still needs verification and a rollback procedure.
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_user_policy" "seal" {
  name = "openbao-seal"
  user = aws_iam_user.runtime.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["kms:Encrypt", "kms:Decrypt", "kms:DescribeKey"]
      Resource = aws_kms_key.seal.arn
    }]
  })
}

resource "cloudfoundry_app" "openbao" {
  name         = local.name
  org_name     = local.dev_config.org_name
  space_name   = cloudfoundry_space.runtime.name
  docker_image = local.dev_config.runtime_image
  command      = "/usr/local/bin/openbao-stack runtime"
  no_route     = true
  instances    = 1
  memory       = "512M"
  disk_quota   = "1G"

  # A sealed or uninitialized process must start before the broker can initialize.
  # The broker verifies API readiness before reporting success
  health_check_type = "port"

  service_bindings = [{ service_instance = cloudfoundry_service_instance.database.name }]

  environment = {
    BAO_LOCAL_CONFIG          = local.runtime_config
    BAO_DATABASE_CA_PEM       = local.dev_config.rds_ca_pem
    AWS_REGION                = local.dev_config.aws_region
    AWS_ACCESS_KEY_ID         = aws_iam_access_key.runtime.id
    AWS_SECRET_ACCESS_KEY     = aws_iam_access_key.runtime.secret
    AWS_EC2_METADATA_DISABLED = "true"
    AWS_USE_FIPS_ENDPOINT     = "true"
  }

  depends_on = [aws_iam_user_policy.seal, cloudfoundry_security_group.runtime]
}

data "cloudfoundry_domain" "internal" {
  name = "apps.internal"
}

resource "cloudfoundry_route" "internal" {
  space        = cloudfoundry_space.runtime.id
  domain       = data.cloudfoundry_domain.internal.id
  host         = local.name
  destinations = [{ app_id = cloudfoundry_app.openbao.id }]

  lifecycle {
    precondition {
      condition     = data.cloudfoundry_domain.internal.internal
      error_message = "The apps.internal domain must be configured for internal traffic."
    }
  }
}

resource "terraform_data" "bootstrap" {
  input = {
    endpoint      = local.endpoint
    app_guid      = cloudfoundry_app.openbao.id
    root_ref      = var.management_credential_ref
    recovery_ref  = local.recovery_ref
    aws_region    = local.dev_config.aws_region
    parameter_key = local.dev_config.parameter_key_id
  }

  provisioner "local-exec" {
    command = "/app/openbao-stack bootstrap"
    environment = {
      OPENBAO_REQUEST = jsonencode(merge(self.input, {
        recovery_pgp_key = local.dev_config.recovery_pgp_key
      }))
    }
  }

  depends_on = [cloudfoundry_route.internal, cloudfoundry_network_policy.management]
}

resource "cloudfoundry_network_policy" "management" {
  policies = [{
    source_app      = var.broker_app_guid
    destination_app = cloudfoundry_app.openbao.id
    protocol        = "tcp"
    port            = "61443"
  }]
}

resource "terraform_data" "root_custody" {
  input = {
    root_ref   = var.management_credential_ref
    aws_region = local.dev_config.aws_region
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "/app/openbao-stack root-delete"
    environment = { OPENBAO_REQUEST = jsonencode(self.input) }
  }

  depends_on = [terraform_data.owner]
}
