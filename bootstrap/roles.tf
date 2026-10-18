# Pipeline: zarządza wszystkim w RG Foundry (zasób, projekt, modele)
resource "azurerm_role_assignment" "github_contributor" {
  scope                = azurerm_resource_group.foundry.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
  principal_type       = "ServicePrincipal"
}

# Pipeline: czyta i zapisuje stan Terraforma
resource "azurerm_role_assignment" "github_state" {
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
  principal_type       = "ServicePrincipal"
}

# Ty: podgląd stanu z laptopa (terraform plan lokalnie)
resource "azurerm_role_assignment" "me_state" {
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}
