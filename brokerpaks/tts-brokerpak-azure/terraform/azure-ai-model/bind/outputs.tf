output "model_name" {
  value = var.model_name
}

output "model_version" {
  value = var.model_version
}

output "api_key" {
  sensitive = true
  value     = var.api_key
}

output "endpoint_url" {
  value = var.endpoint_url
}
