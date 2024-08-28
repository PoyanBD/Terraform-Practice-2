data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

data "azuread_client_config" "current" {}

data "azurerm_policy_definition_built_in" "disallow_sa_public_access" {
  display_name = "Storage accounts should disable public network access"
}
