output "auth_mount" {
    value = "approle"
}
output "role_id" {
    value = ""
}
output "secret_id" {
    value = ""
    sensitive = true
}
output "secret_id_ttl_seconds" {
    value = "86400"
}
output "path_prefix" {
    value = var.path_prefix
}
output "access" {
    value = var.access
}