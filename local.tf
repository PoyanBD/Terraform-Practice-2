locals {
  policies = {
    "disallow_sa_public_access" = {
      policy_id        = "${data.azurerm_policy_definition_built_in.disallow_sa_public_access.id}"
      parameter_values = jsonencode({})
    }
  }
}
