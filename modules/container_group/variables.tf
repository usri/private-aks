variable resource_group {
  description = "Resource group name"
  type        = string
}

variable location {
  description = "Location where Firewall will be deployed"
  type        = string
}

variable container_group_name {
  description = "Name of the container group"
  type        = string
}

variable subnet_id {
  description = "Subnet ID to bind the container group to"
  type        = string
}

variable dns_zone_resource_group {
  description = "Resource group where the private DNS zone is deployed"
  type        = string
}

variable dns_zone_name {
  description = "Name of the private DNS zone"
  type        = string
}

variable vnet_id {
  description = "VNET ID to bind the container group to"
  type        = string
}


