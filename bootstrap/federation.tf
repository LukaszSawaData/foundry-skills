# Tworzone po kolei - równoległe zapisy do jednej tożsamości kończą się błędem
resource "azurerm_federated_identity_credential" "pr" {
  name      = "gh-pr"
  parent_id = azurerm_user_assigned_identity.github.id
  audience  = ["api://AzureADTokenExchange"]
  issuer    = local.issuer
  subject   = "${local.subject}:pull_request"
}

resource "azurerm_federated_identity_credential" "main" {
  name       = "gh-main"
  parent_id  = azurerm_user_assigned_identity.github.id
  audience   = ["api://AzureADTokenExchange"]
  issuer     = local.issuer
  subject    = "${local.subject}:ref:refs/heads/main"
  depends_on = [azurerm_federated_identity_credential.pr]
}

resource "azurerm_federated_identity_credential" "production" {
  name       = "gh-production"
  parent_id  = azurerm_user_assigned_identity.github.id
  audience   = ["api://AzureADTokenExchange"]
  issuer     = local.issuer
  subject    = "${local.subject}:environment:production"
  depends_on = [azurerm_federated_identity_credential.main]
}
