resource "github_repository_environment" "production" {
  repository  = var.github_repo
  environment = "production"

  reviewers {
    users = [data.github_user.reviewer.id]
  }

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment_deployment_policy" "main_only" {
  repository     = var.github_repo
  environment    = github_repository_environment.production.environment
  branch_pattern = "main"
}
