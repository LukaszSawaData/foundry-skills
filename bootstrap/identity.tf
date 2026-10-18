resource "azurerm_user_assigned_identity" "github" {
  name                = "id-${var.prefix}-github"
  resource_group_name = azurerm_resource_group.state.name
  location            = var.location
}

data "github_user" "owner" {
  username = var.github_owner
}

data "github_repository" "repo" {
  full_name = "${var.github_owner}/${var.github_repo}"
}

locals {
  # GitHub wysyła subject z numerycznymi ID: repo:<owner>@<id>/<repo>@<id>:...
  subject = "repo:${var.github_owner}@${data.github_user.owner.id}/${var.github_repo}@${data.github_repository.repo.repo_id}"
  issuer  = "https://token.actions.githubusercontent.com"
}
