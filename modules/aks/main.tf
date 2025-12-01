# -----------------------------------------------------------------------------
# Azure Kubernetes Service Module
# Creates AKS cluster with environment-specific configuration
# -----------------------------------------------------------------------------

locals {
  # Node pool configuration by environment
  node_pool_config = {
    dev = {
      vm_size         = "Standard_B2s_v2"
      node_count      = 1
      min_count       = null
      max_count       = null
      enable_autoscaling = false
    }
    staging = {
      vm_size         = "Standard_B4s_v2"
      node_count      = 2
      min_count       = 1
      max_count       = 4
      enable_autoscaling = true
    }
    prod = {
      vm_size         = "Standard_D4s_v5"
      node_count      = 3
      min_count       = 3
      max_count       = 10
      enable_autoscaling = true
    }
  }

  config = local.node_pool_config[var.environment]
}

# -----------------------------------------------------------------------------
# AKS Cluster
# -----------------------------------------------------------------------------

resource "azurerm_kubernetes_cluster" "this" {
  name                = "aks-tekton-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "aks-tekton-${var.environment}"
  kubernetes_version  = var.kubernetes_version

  # System node pool
  default_node_pool {
    name                = "system"
    vm_size             = local.config.vm_size
    node_count          = local.config.enable_autoscaling ? null : local.config.node_count
    min_count           = local.config.enable_autoscaling ? local.config.min_count : null
    max_count           = local.config.enable_autoscaling ? local.config.max_count : null
    enable_auto_scaling = local.config.enable_autoscaling
    vnet_subnet_id      = var.subnet_id
    os_disk_size_gb     = 50
    type                = "VirtualMachineScaleSets"

    # Enable zone redundancy for production
    zones = var.environment == "prod" ? ["1", "2", "3"] : null

    node_labels = {
      "environment" = var.environment
      "nodepool"    = "system"
    }

    tags = {
      environment = var.environment
      project     = "tekton"
    }
  }

  # Managed Identity
  identity {
    type = "SystemAssigned"
  }

  # Network configuration
  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = "172.16.0.0/16"
    dns_service_ip    = "172.16.0.10"
  }

  # Azure AD RBAC (optional)
  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
  }

  # Monitoring addon
  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  # Key Vault secrets provider
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  # Auto-upgrade channel
  automatic_channel_upgrade = var.environment == "prod" ? "stable" : "rapid"

  # Maintenance window for production
  dynamic "maintenance_window" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      allowed {
        day   = "Sunday"
        hours = [2, 3, 4]
      }
    }
  }

  tags = merge(
    {
      environment = var.environment
      project     = "tekton"
      managed_by  = "terraform"
    },
    var.additional_tags
  )

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      kubernetes_version
    ]
  }
}

# -----------------------------------------------------------------------------
# User Node Pool (for workloads)
# -----------------------------------------------------------------------------

resource "azurerm_kubernetes_cluster_node_pool" "workload" {
  count                 = var.environment != "dev" ? 1 : 0
  name                  = "workload"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = local.config.vm_size
  node_count            = local.config.enable_autoscaling ? null : local.config.node_count
  min_count             = local.config.enable_autoscaling ? local.config.min_count : null
  max_count             = local.config.enable_autoscaling ? local.config.max_count : null
  enable_auto_scaling   = local.config.enable_autoscaling
  vnet_subnet_id        = var.subnet_id
  os_disk_size_gb       = 100
  mode                  = "User"

  zones = var.environment == "prod" ? ["1", "2", "3"] : null

  node_labels = {
    "environment" = var.environment
    "nodepool"    = "workload"
  }

  node_taints = []

  tags = {
    environment = var.environment
    project     = "tekton"
    managed_by  = "terraform"
  }

  lifecycle {
    ignore_changes = [
      node_count
    ]
  }
}
