# Based on this example: https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/tree/main/examples/default

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = ">= 0.3.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = var.location
  name     = "avm-res-cognitiveservices-account-${module.naming.resource_group.name_unique}"
}

module "avm_res_cognitiveservices_account" {
  source  = "Azure/avm-res-cognitiveservices-account/azurerm"
  version = "0.6.0"

  # Required configuration
  kind                = "OpenAI"
  location            = azurerm_resource_group.this.location
  name                = "cloudgov-${module.naming.cognitive_account.name_unique}"
  sku_name            = "S0"
  resource_group_name = azurerm_resource_group.this.name

  # Model configuration
  cognitive_deployments = {
    "instance" = {
      name = var.model_name
      model = {
        format  = "OpenAI"
        name    = var.model_name
        version = var.model_version
      }
      scale = {
        type = "Standard"
      }
    }
  }
}
