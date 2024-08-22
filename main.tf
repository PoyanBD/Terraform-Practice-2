#1

resource "random_string" "main" {
  length  = 4
  upper   = false
  special = false
}

resource "azurerm_resource_group" "main" {
  name     = "rg-first-${random_string.main.result}"
  location = var.location
}

resource "azurerm_storage_account" "main" {
  name                     = "st${random_string.main.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-first${random_string.main.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

#2

resource "azurerm_virtual_network" "main" {
  name                = "vnet-first${random_string.main.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.1.0/16"]
}

resource "azurerm_subnet" "default" {
  name                 = "snet-default"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "default" {
  name                = "nsg-default"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_network_security_rule" "rule1" {
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.default.name

  name                       = "rule-100"
  priority                   = 100
  direction                  = "Outbound"
  access                     = "Allow"
  protocol                   = "*"
  source_port_range          = "*"
  destination_port_range     = "*"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}

resource "azurerm_subnet_network_security_group_association" "default_rule1" {
  subnet_id                 = azurerm_subnet.default.id
  network_security_group_id = azurerm_network_security_group.default.id
}

#3

resource "azurerm_key_vault" "main" {
  name                     = "kv-first-${random_string.main.result}"
  location                 = var.location
  resource_group_name      = azurerm_resource_group.main.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled = false
  sku_name                 = "standard"
}

resource "azurerm_key_vault_access_policy" "terraform_user" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions    = ["Get", "List", "Create"]
  secret_permissions = ["Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"]

}

#4

resource "azurerm_public_ip" "main" {
  name                = "pip-vm${random_string.main.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "main" {
  name                = "nic-vm${random_string.main.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  ip_configuration {
    name                          = "public"
    subnet_id                     = azurerm_subnet.default.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

#5

resource "azurerm_bastion_host" "main" {
  name                = "bas${random_string.main.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.default.id
    public_ip_address_id = azurerm_public_ip.main.id
  }
}