resource "random_id" "prefix" {
  byte_length = 8
}

resource "azurerm_resource_group" "main" {
  count = var.create_resource_group ? 1 : 0

  location = var.location
  name     = coalesce(var.resource_group_name, "${random_id.prefix.hex}-rg")
}

locals {
  resource_group = {
    name     = var.create_resource_group ? azurerm_resource_group.main[0].name : var.resource_group_name
    location = var.location
  }
}

resource "azurerm_virtual_network" "test" {
  address_space       = ["10.52.0.0/16"]
  location            = local.resource_group.location
  name                = "${random_id.prefix.hex}-vn"
  resource_group_name = local.resource_group.name
}

resource "azurerm_subnet" "test" {
  address_prefixes     = ["10.52.0.0/24"]
  name                 = "${random_id.prefix.hex}-sn"
  resource_group_name  = local.resource_group.name
  virtual_network_name = azurerm_virtual_network.test.name
  enforce_private_link_endpoint_network_policies = true
}

# locals {
#   nodes = {
#     for i in range(1) : "worker${i}" => {
#       name           = substr("worker${i}${random_id.prefix.hex}", 0, 8)
#       vm_size        = "Standard_B2s"
#       node_count     = 1
#       vnet_subnet_id = azurerm_subnet.test.id
#       zones          = [1, 2, 3]
#     }
#   }
# }

# resource "azurerm_kubernetes_cluster" "main" {
#   # Existing configuration for the resource

#   api_server_access_profile {
#     authorized_ip_ranges = var.public_network_access_enabled ? ["0.0.0.0/32"] : []
#   }
# }


# resource "kubernetes_cluster_role_binding" "admin_binding" {
#   metadata {
#     name = "admin-binding"
#   }

#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = "cluster-admin"
#   }

#   subject {
#     kind      = "User"
#     name      = "aryan.sachiv@bdb.ai"
#     api_group = "rbac.authorization.k8s.io"
#   }
# }

resource "random_string" "acr_suffix" {
  length  = 8
  upper   = false
  numeric = true
  special = false
}

resource "azurerm_container_registry" "example" {
  location            = local.resource_group.location
  name                = "aksacrtest${random_string.acr_suffix.result}"
  resource_group_name = local.resource_group.name
  sku                 = "Basic"

  # retention_policy {
  #   days    = 14
  #   enabled = true
  # }
}

module "aks" {
  source  = "git::https://github.com/Aryankanth/aksterraform.git"
  # version = "v7.0.0"

  prefix              = "prefix-${random_id.prefix.hex}"
  resource_group_name = local.resource_group.name
  os_disk_size_gb     = 30
  public_network_access_enabled     = true
  sku_tier                          = "Standard"
  rbac_aad                          = true
  role_based_access_control_enabled = true
  vnet_subnet_id                    = azurerm_subnet.test.id
  # nodepool                          = var.agents_size
  agents_size  = var.agents_size
  agents_count = var.agents_count
  attached_acr_id_map = {
    example = azurerm_container_registry.example.id
  }

  private_cluster_enabled = false
  rbac_aad_managed        = true
  # api_server_authorized_ip_ranges = ["0.0.0.0/0"]
  # api_server_authorized_ip_ranges     = var.api_server_authorized_ip_ranges
  # api_server_access_profile {
  #     authorized_ip_ranges = var.public_network_access_enabled ? ["0.0.0.0/0"] : []
  #   }
  api_server_authorized_ip_ranges = var.public_network_access_enabled ? ["0.0.0.0/0"] : ["0.0.0.0/32"]



}







