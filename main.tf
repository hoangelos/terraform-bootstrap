terraform {
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
      version = "2.41.0"
    }
    random = {
      source = "hashicorp/random"
      version = "3.5.1"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.72.0"
    }
    local = {
      source = "hashicorp/local"
      version = "2.4.0"
    }
    tss = {
      source = "norskhelsenett/tss"
      version = "0.3.0"
    }
  }
}

provider "azuread" {}

provider "random" {}

provider "azurerm" {
  features {}
}

provider "local" {}

provider "tss" {
  username   = var.tss_username
  password   = var.tss_password
  domain     = var.tss_domain
  server_url = var.tss_server_url
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "state" {
  name = var.resource_group_name
}

resource "azurerm_management_lock" "terraform-resource-group" {
  name       = "terraform"
  scope      = data.azurerm_resource_group.state.id
  lock_level = "CanNotDelete"
  notes      = "Protects the terraform state files and key vault."
}

resource "azurerm_role_assignment" "rg_aad_group" {
  for_each = toset(var.terraform_state_aad_principals["groups"])

  scope                = data.azurerm_resource_group.state.id
  role_definition_name = "Reader"
  principal_id         = data.azuread_group.terraform_state_aad_group[each.value].object_id
}

resource "azurerm_role_assignment" "rg_aad_users" {
  for_each = toset(var.terraform_state_aad_principals["users"])

  scope                = data.azurerm_resource_group.state.id
  role_definition_name = "Reader"
  principal_id         = data.azuread_user.terraform_state_aad_users[each.value].object_id
}

resource "azurerm_role_assignment" "rg_aad_sps" {
  for_each = toset(var.terraform_state_aad_principals["service_principals"])

  scope                = data.azurerm_resource_group.state.id
  role_definition_name = "Reader"
  principal_id         = data.azuread_service_principal.terraform_state_aad_sps[each.value].object_id
}

locals {
  location = coalesce(var.location, data.azurerm_resource_group.state.location)
  tags     = merge(data.azurerm_resource_group.state.tags, var.tags)
}
