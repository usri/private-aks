variable "location" {
  type        = string
  description = "The resource group location"
  default     = "eastus"
}

variable "vnet_resource_group_name" {
  type        = string
  description = "The resource group name to be created"
  default     = "hub-rg"
}

variable "hub_vnet_name" {
  type        = string
  description = "Hub VNET name"
  default     = "hub-vnet"
}

variable "kube_vnet_name" {
  type        = string
  description = "AKS VNET name"
  default     = "spoke1-vnet"
}

variable "kube_version_prefix" {
  type        = string
  description = "AKS Kubernetes version prefix. Formatted '[Major].[Minor]' like '1.18'. Patch version part (as in '[Major].[Minor].[Patch]') will be set to latest automatically."
  default     = "1.18"
}

variable "kube_resource_group_name" {
  type        = string
  description = "The resource group name to be created"
  default     = "spoke1-rg"
}

variable "nodepool_nodes_count" {
  type        = string
  description = "Default nodepool nodes count"
  default     = 1
}

variable "nodepool_vm_size" {
  type        = string
  description = "Default nodepool VM size"
  default     = "Standard_D2_v2"
}

variable "network_docker_bridge_cidr" {
  type        = string
  description = "CNI Docker bridge cidr"
  default     = "172.17.0.1/16"
}

variable "network_dns_service_ip" {
  type        = string
  description = "CNI DNS service IP"
  default     = "10.2.0.10"
}

variable "network_service_cidr" {
  description = "CNI service cidr"
  default     = "10.2.0.0/24"
}

variable "tags" {
  type = map(string)
  default = {
    "Environment" = "Development"
    "Project"     = "PrivateAKS"
    "BillingCode" = "Internal"
  }
}
