locals {
  rbac_assignments = {
    for assignment in var.service_principal_rbac_assignments :
    md5("${assignment.role}-${assignment.scope}") => assignment // Should remain as a predictable hash key
  }
}

data "azuread_service_principal" "terraform" {
  display_name = var.service_principal_name
}

resource "azurerm_role_assignment" "storage_blob_contributor_service_principal" {
  scope                = data.azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azuread_service_principal.terraform.object_id
}

resource "azurerm_role_assignment" "custom_rbac_assignments" {
  for_each = local.rbac_assignments

  scope                = length(regexall("^[Cc]urrent$", each.value["scope"])) > 0 ? "/subscriptions/${data.azurerm_client_config.current.subscription_id}" : each.value["scope"]
  role_definition_name = each.value["role"]
  principal_id         = data.azuread_service_principal.terraform.object_id
}
