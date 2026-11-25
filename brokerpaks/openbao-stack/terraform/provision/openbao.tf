# The computed bootstrap output defers provider configuration on the first
# apply until the server has been initialized and its root token saved in SSM.
provider "vault" {
  address            = terraform_data.bootstrap.output.endpoint
  token              = ""
  add_address_to_env = "true"
  skip_child_token   = true
  skip_tls_verify    = false
}

resource "vault_mount" "kv" {
  path    = "secret"
  type    = "kv"
  options = { version = "2" }
}

resource "vault_auth_backend" "approle" {
  path = "approle"
  type = "approle"
}