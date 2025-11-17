variable "resource_group_name" {
  description = "Nom du resource group"
  type        = string
  default     = "rg-vulnscanner"
}

variable "location" {
  description = "Région Azure"
  type        = string
  default     = "francecentral"
}

variable "vm_size" {
  description = "Taille de la VM"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Username admin VM"
  type        = string
  default     = "azureuser"
}

variable "github_repo_url" {
  description = "URL du repo GitHub de l'application"
  type        = string
  default     = "https://github.com/vulne-app/vulnscanner-app.git"
}