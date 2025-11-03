# Root Terragrunt Configuration for Azure PaaS
locals {
  env         = basename(get_terragrunt_dir())
  region      = get_env("AZURE_REGION", "France Central")
  tags = {
    Environment = local.env
    ManagedBy   = "Terragrunt"
    Project     = "TerraCloud"
  }
}

remote_state {
  backend = "azurerm"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    resource_group_name  = get_env("TF_STATE_RG", "rg-stg_1")
    storage_account_name = get_env("TF_STATE_SA", "terracloudtfstate")
    container_name       = "tfstate"
    key                  = "${local.env}/terraform.tfstate"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}
EOF
}
