data "azurerm_resource_group" "foundry" {
  name = var.resource_group_name
}

resource "azapi_resource" "foundry" {
  type      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  name      = "${var.prefix}-foundry"
  parent_id = data.azurerm_resource_group.foundry.id
  location  = var.location

  identity {
    type = "SystemAssigned"
  }

  body = {
    kind = "AIServices"
    sku  = { name = "S0" }
    properties = {
      allowProjectManagement = true
      customSubDomainName    = "${var.prefix}-foundry"
      publicNetworkAccess    = "Enabled"
      disableLocalAuth       = true
    }
  }
}

resource "azapi_resource" "project" {
  type      = "Microsoft.CognitiveServices/accounts/projects@2025-06-01"
  name      = "models"
  parent_id = azapi_resource.foundry.id
  location  = var.location

  identity {
    type = "SystemAssigned"
  }

  body = {
    properties = {
      displayName = "Models GitOps"
      description = "Deploymenty modeli zarządzane przez PR"
    }
  }
}
