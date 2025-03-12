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

output "no_route" {
  value       = var.no_route
  description = "Feature flag. If true, the CSB and CSB Helper have been configured to be unroutable. This exists so the CSB can be deployed to production but not made available to users. Default false."
}
