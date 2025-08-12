output "org_name" {
  value       = data.cloudfoundry_org.platform.name
  description = "Used by the terraform-cleanup step."
}

output "space_name" {
  value       = data.cloudfoundry_space.brokers.name
  description = "Used by the terraform-cleanup step."
}

output "app_name" {
  value       = cloudfoundry_app.csb.name
  description = "Used by the terraform-cleanup step."
}

output "helper_app_name" {
  value       = cloudfoundry_app.helper.name
  description = "Used by the terraform-cleanup step."
}
