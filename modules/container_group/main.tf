resource "random_id" "id" {
	  byte_length = 4
}
locals {
  cloud_shell_stg_acct_name = lower("${random_id.id.hex}shellstg")
}
resource "azurerm_network_profile" "network_profile" {
  name                = "network-profile"
  location            = var.location
  resource_group_name = var.resource_group

  container_network_interface {
    name = "bastion-aci-nic"

    ip_configuration {
      name      = "bastion-ip-config"
      subnet_id = var.subnet_id
    }
  }
}

resource "azurerm_container_group" "mgmt" {
  name                = var.container_group_name
  location            = var.location
  resource_group_name = var.resource_group
  ip_address_type     = "Private"
  os_type             = "Linux"
  restart_policy      = "Never"
  network_profile_id  = azurerm_network_profile.network_profile.id

  container {
    name   = "azure-cloud-shell"
    image  = "mcr.microsoft.com/azure-cloudshell"
    cpu    = 1.0
    memory = 1.5

    volume {
      name                 = "mgmt"
      mount_path           = "/data"
      share_name           = azurerm_storage_share.cloud_shell_share.name
      storage_account_name = local.cloud_shell_stg_acct_name
      storage_account_key  = azurerm_storage_account.cloud_shell_stg.primary_access_key
    }

    ports {
      port     = 80
      protocol = "TCP"
    }

    commands = [ "tail", "-f", "/dev/null" ]
  }
}

resource "azurerm_storage_account" "cloud_shell_stg" {
  name                     = local.cloud_shell_stg_acct_name
  resource_group_name      = var.resource_group
  location                 = var.location
  account_kind             = "FileStorage"
  account_tier             = "Premium"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "cloud_shell_share" {
  name                 = "mgmt-data"
  storage_account_name = azurerm_storage_account.cloud_shell_stg.name
  quota                = 100
}

resource "azurerm_storage_account_network_rules" "cloud_shell_stg_nr" {
  storage_account_name       = azurerm_storage_account.cloud_shell_stg.name
  resource_group_name        = var.resource_group
  default_action             = "Deny"
  virtual_network_subnet_ids = [ var.subnet_id ]

  depends_on = [ 
    azurerm_storage_share.cloud_shell_share,
    azurerm_container_group.mgmt 
  ]
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_vnet_link" {
  name                  = "hub-dnsvnetlink"
  resource_group_name   = var.dns_zone_resource_group
  private_dns_zone_name = var.dns_zone_name
  virtual_network_id    = var.vnet_id
}