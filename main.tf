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

#6

resource "azurerm_virtual_network_gateway" "vpn" {
  name                = "vgw-${random_string.main.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "Basic"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn-pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.default.id
  }

  vpn_client_configuration {
    address_space        = ["10.2.0.0/24"]
    vpn_auth_types       = ["AAD"]
    aad_tenant           = ""
    aad_audience         = ""
    aad_issuer           = "*/"
    vpn_client_protocols = ["OpenVPN"]
  }

}

#11

resource "azuread_application" "web_api" {
  display_name = "Example Api"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "web_api" {
  client_id                    = azuread_application.web_api.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "time_rotating" "one_week" {
  rotation_days = 7
}

resource "azuread_service_principal_password" "web_app_allow_web_api" {
  display_name         = "Web app"
  service_principal_id = azuread_service_principal.web_api.object_id
  rotate_when_changed = {
    rotation = time_rotating.one_week.id
  }
}

#12

resource "azurerm_subscription_policy_assignment" "disallow_sa_public_access" {
  name                 = "DisallowSAPublicAccess"
  policy_definition_id = data.azurerm_policy_definition_built_in.disallow_sa_public_access.id
  subscription_id      = data.azurerm_subscription.current.id

  parameters = jsonencode(
    {
      effect = {
        value = "Deny"
      }
    }
  )
}

#14
