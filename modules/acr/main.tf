resource "random_id" "id" {
    byte_length = 4
}
locals {
    acr_name = lower("${random_id.id.hex}acr")
}

resource "azurerm_container_registry" "acr" {
    name                = local.acr_name
    location            = var.location
    resource_group_name = var.resource_group
    sku                 = "Premium"
    admin_enabled       = false
}
