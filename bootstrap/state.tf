data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "state" {
  name     = "rg-${var.prefix}-state"
  location = var.location
}

# Pusta RG na Foundry - wypełnia ją pipeline
resource "azurerm_resource_group" "foundry" {
  name     = "rg-${var.prefix}-foundry"
  location = var.location
}

resource "azurerm_storage_account" "state" {
  name                            = "${var.prefix}tfstate"
  resource_group_name             = azurerm_resource_group.state.name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false

  blob_properties {
    versioning_enabled = true
  }
}

resource "azurerm_storage_container" "state" {
  name               = "tfstate"
  storage_account_id = azurerm_storage_account.state.id
}
