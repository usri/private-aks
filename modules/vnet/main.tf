resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "subnet" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints
  dynamic "delegation" {
    for_each = each.value.delegations
    content {
      name = delegation.value
      service_delegation {
        name    = delegation.value
        actions = [ "Microsoft.Network/virtualNetworks/subnets/action" ]
      }
    }
  }
}