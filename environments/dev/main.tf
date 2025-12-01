# -----------------------------------------------------------------------------
# Main Configuration - Dev Environment
# Orchestrates all modules for the development environment
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Resource Group
# -----------------------------------------------------------------------------

module "resource_group" {
  source = "../../modules/resource-group"

  environment     = var.environment
  location        = var.location
  additional_tags = var.additional_tags
}

# -----------------------------------------------------------------------------
# Monitoring (created first for Log Analytics workspace ID)
# -----------------------------------------------------------------------------

module "monitoring" {
  source = "../../modules/monitoring"

  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  aks_cluster_id      = null
  additional_tags     = var.additional_tags

  depends_on = [module.resource_group]
}

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------

module "network" {
  source = "../../modules/network"

  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  additional_tags     = var.additional_tags

  depends_on = [module.resource_group]
}

# -----------------------------------------------------------------------------
# Azure Kubernetes Service
# -----------------------------------------------------------------------------

module "aks" {
  source = "../../modules/aks"

  environment                = var.environment
  location                   = var.location
  resource_group_name        = module.resource_group.name
  subnet_id                  = module.network.aks_subnet_id
  kubernetes_version         = var.kubernetes_version
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  additional_tags            = var.additional_tags

  depends_on = [module.network, module.monitoring]
}

# -----------------------------------------------------------------------------
# Azure Container Registry
# -----------------------------------------------------------------------------

module "acr" {
  source = "../../modules/acr"

  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  aks_principal_id    = module.aks.kubelet_identity[0].object_id
  additional_tags     = var.additional_tags

  depends_on = [module.aks]
}

# -----------------------------------------------------------------------------
# Azure Key Vault
# -----------------------------------------------------------------------------

module "keyvault" {
  source = "../../modules/keyvault"

  environment                    = var.environment
  location                       = var.location
  resource_group_name            = module.resource_group.name
  aks_principal_id               = module.aks.identity_principal_id
  aks_kubelet_identity_object_id = module.aks.kubelet_identity[0].object_id
  subnet_ids                     = [module.network.aks_subnet_id]
  additional_tags                = var.additional_tags

  depends_on = [module.aks]
}
