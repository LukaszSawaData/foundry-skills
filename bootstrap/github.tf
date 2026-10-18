data "github_user" "reviewer" {
  username = var.github_reviewer
}

locals {
  gh_vars = {
    AZURE_CLIENT_ID       = azurerm_user_assigned_identity.github.client_id
    AZURE_TENANT_ID       = data.azurerm_client_config.current.tenant_id
    AZURE_SUBSCRIPTION_ID = var.subscription_id
    TFSTATE_RG            = azurerm_resource_group.state.name
    TFSTATE_ACCOUNT       = azurerm_storage_account.state.name
    FOUNDRY_RG            = azurerm_resource_group.foundry.name
    PREFIX                = var.prefix
    LOCATION              = var.location
  }
}

resource "github_actions_variable" "vars" {
  for_each      = local.gh_vars
  repository    = var.github_repo
  variable_name = each.key
  value         = each.value
}
