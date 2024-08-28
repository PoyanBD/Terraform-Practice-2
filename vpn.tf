resource "azurerm_public_ip" "vpn-pip" {
  name                = "vpn-pip${random_string.main.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  allocation_method   = "Dynamic"
}
