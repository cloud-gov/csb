variable "model_name" {
  type        = string
  description = "The name of the AI model."
}

variable "model_version" {
  type        = string
  description = "The version of the AI model."
}

variable "api_key" {
  description = "The API key for accessing the AI model."
  sensitive   = true
}

variable "endpoint_url" {
  description = "The constructed endpoint URL for the AI model."
}
