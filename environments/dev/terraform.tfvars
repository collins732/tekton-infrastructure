# -----------------------------------------------------------------------------
# Terraform Variables - Dev Environment
# Small resources for development and testing
# -----------------------------------------------------------------------------

subscription_id    = "1f6ffd0f-1c29-4c90-8b69-69e008374b98"
environment        = "dev"
location           = "francecentral"
kubernetes_version = "1.31"

additional_tags = {
  cost_center = "development"
  team        = "devops"
}
