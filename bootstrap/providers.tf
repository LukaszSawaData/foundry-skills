terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }
    github  = { source = "integrations/github", version = "~> 6.0" }
    local   = { source = "hashicorp/local", version = "~> 2.5" }
  }
}

provider "azurerm" {
  features {}
  subscription_id     = var.subscription_id
  storage_use_azuread = true
}

provider "github" {
  owner = var.github_owner
}
