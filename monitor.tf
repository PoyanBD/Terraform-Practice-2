resource "random_string" "activity_log" {
  length  = 4
  upper   = false
  special = false
}

resource "random_string" "keyvault_monitor" {
  length  = 8
  upper   = false
  special = false
}

resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  name                       = "diag-${random_string.activity_log.result}"
  target_resource_id         = data.azurerm_subscription.current.id
  storage_account_id         = azurerm_storage_account.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log { category = "Administrative" }
  enabled_log { category = "ServiceHealth" }
  enabled_log { category = "Alert" }
  enabled_log { category = "Recommendation" }
  enabled_log { category = "Policy" }
  enabled_log { category = "AutoScale" }
  enabled_log { category = "ResourceHealth" }
}

resource "azurerm_monitor_diagnostic_setting" "keyvault_log" {
  name                       = "diag-${random_string.keyvault_monitor.result}"
  target_resource_id         = azurerm_key_vault.main.id
  storage_account_id         = azurerm_storage_account.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log { category_group = "audit" }
  enabled_log { category_group = "allLogs" }
  
  metric { category = "AllMetrics" }
}