output "service_name" {
  description = "The name of the Azure AI service"
  value       = module.avm_res_cognitiveservices_account.name
}

output "model_name" {
  description = "The name of the AI model (deployment name)"
  value       = var.model_name
}

output "model_version" {
  description = "The version of the AI model"
  value       = var.model_version
}

# The primary key from the Cognitive Services account
output "api_key" {
  description = "The API key for accessing the AI model"
  value       = module.avm_res_cognitiveservices_account.primary_access_key
  sensitive   = true
}

# Construct a model endpoint URL referencing the deployment name
output "endpoint_url" {
  description = "The constructed endpoint URL for the AI model"
  value       = format("%s/openai/deployments/%s", module.avm_res_cognitiveservices_account.endpoint, var.model_name)
}
