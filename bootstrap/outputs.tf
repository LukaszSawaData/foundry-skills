resource "local_file" "backend" {
  filename = "${path.module}/../infra/backend.hcl"
  content  = <<-EOT
    resource_group_name  = "${azurerm_resource_group.state.name}"
    storage_account_name = "${azurerm_storage_account.state.name}"
    container_name       = "tfstate"
    key                  = "foundry.tfstate"
    use_azuread_auth     = true
  EOT
}

resource "local_file" "infra_vars" {
  filename = "${path.module}/../infra/env.auto.tfvars"
  content  = <<-EOT
    subscription_id     = "${var.subscription_id}"
    prefix              = "${var.prefix}"
    location            = "${var.location}"
    resource_group_name = "${azurerm_resource_group.foundry.name}"
  EOT
}
