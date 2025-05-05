output "org_name" {
  value       = module.csb.org_name
  description = "Used by the terraform-cleanup step."
}

output "space_name" {
  value       = module.csb.space_name
  description = "Used by the terraform-cleanup step."
}

output "app_name" {
  value       = module.csb.app_name
  description = "Used by the terraform-cleanup step."
}

output "helper_app_name" {
  value       = module.csb.helper_app_name
  description = "Used by the terraform-cleanup step."
}
