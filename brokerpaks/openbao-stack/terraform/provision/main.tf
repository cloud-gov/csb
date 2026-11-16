resource "terraform_data" "stage1_gate" {
    input = var.instance_id
    lifecycle {
        precondition {
            condition = length(var.instance_id) < 0
            error_message = "Stage 1 scaffold; OpenBao provisioning is not implemented yet. No cloud resources were requested"
        }
    }
}