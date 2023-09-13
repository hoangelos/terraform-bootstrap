data "azuread_group" "terraform_state_aad_group" {
  for_each = toset(var.terraform_state_aad_principals["groups"])
  display_name     = each.value
}

data "azuread_user" "terraform_state_aad_users" {
  for_each = toset(var.terraform_state_aad_principals["users"])
  user_principal_name     = each.value
}

data "azuread_service_principal" "terraform_state_aad_sps" {
  for_each = toset(var.terraform_state_aad_principals["service_principals"])
  display_name     = each.value
}

data "azurerm_storage_account" "state" {
  name                = var.storage_account_name
  resource_group_name = data.azurerm_resource_group.state.name
}

data "azurerm_storage_container" "tfstate" {
  name                 = var.container_name
  storage_account_name = data.azurerm_storage_account.state.name
}

//=============================================================

resource "azurerm_storage_container" "bootstrap" {
  name                 = "bootstrap"
  storage_account_name = data.azurerm_storage_account.state.name
}

resource "azurerm_role_assignment" "terraform_state_owner" {
  scope                = data.azurerm_storage_account.state.id
  role_definition_name = "Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "terraform_state_aad_group" {
  for_each = toset(var.terraform_state_aad_principals["groups"])

  scope                = data.azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azuread_group.terraform_state_aad_group[each.value].object_id
}

resource "azurerm_role_assignment" "terraform_state_aad_users" {
  for_each = toset(var.terraform_state_aad_principals["users"])

  scope                = data.azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azuread_user.terraform_state_aad_users[each.value].object_id
}

resource "azurerm_role_assignment" "terraform_state_aad_sps" {
  for_each = toset(var.terraform_state_aad_principals["service_principals"])

  scope                = data.azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azuread_service_principal.terraform_state_aad_sps[each.value].object_id
}
