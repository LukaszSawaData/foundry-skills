resource "azapi_resource" "deployment" {
  for_each  = var.deployments
  type      = "Microsoft.CognitiveServices/accounts/deployments@2025-06-01"
  name      = each.key
  parent_id = azapi_resource.foundry.id

  body = {
    sku = {
      name     = each.value.sku
      capacity = each.value.capacity
    }
    properties = {
      model = {
        format  = "OpenAI"
        name    = each.value.model_name
        version = each.value.model_version
      }
    }
  }

  depends_on = [azapi_resource.project]
}

output "project_endpoint" {
  value = "https://${var.prefix}-foundry.services.ai.azure.com/api/projects/${azapi_resource.project.name}"
}

output "deployments" {
  value = { for k, d in var.deployments : k => "${d.model_name} ${d.model_version} (${d.sku}, ${d.capacity}k TPM)" }
}
