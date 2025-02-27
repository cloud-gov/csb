

This seems to be the most-used provider in the tf registry: https://registry.terraform.io/modules/Azure/avm-res-cognitiveservices-account/azurerm/latest

In terms of the actual, minimal infra, I think the need looks a lot like this minimal example: https://github.com/Pwd9000-ML/terraform-azurerm-openai-service/tree/master/examples/Create_OpenAI_Service_and_Models

Minimally, we need an openai service in a given region, and then deployments for the requested models within that service. The broker consumer (me) just needs a vcap_services object with a model array 
that contains the associated service, model deployment name, model version, api key and a constructed endpoint url like https://{{openai_service_name, i.e. 10x-ai-sandbox-east}}.openai.azure.com/openai/deployments/{{model_deployment_name, i.e. text-embedding-3-small-1-230k or west-4o-200k}}

Embedding models are treated just like any other model, nothing special. 

In terms of what the broker user gets to choose, you specify model name and version (default to latest). In terms of scaling capacity, I think by default each azure account is permitted 30 services and each service is permitted 32 model deployments. Each model has specific tokens per minute and requests per minute limits. Tokens per minute limits are quite high for a single gpt4o deployment.  

I think we can treat model version upgrades as just creating a new service alongside the existing previous version and cutting over.