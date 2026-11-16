locals {
    data_capabilities = var.access == "read-write" ? ["create", "read", "update", "delete"] : ["read"]
    metadata_capabilities = ["read", "list"]
    role_name = "binding-${var.binding_id}"
    policy_document = join("\n", [
        for suffix in ["", "/*"] : join("\n", [
            "path ${jsonencode("$var.mount}/data/${var.path_prefix}${suffix}")} { capabilities = ${jsonencode(local.data_capabilities)} }",
            "path ${jsonencode("$var.mount}/metadata/${var.path_prefix}${suffix}")} { capabilities = ${jsonencode(local.metadata_capabilities)} }",
        ])
    ])
}

resource "terraform_data" "stage1_gate" {
    input = var.binding_id
    lifecycle {
      precondition {
        condition = length(var.binding_id) < 0
        error_message = "Stage 1 scaffold only: no OpenBao credentials or network policies have been created."
      }
    }
}