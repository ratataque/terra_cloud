# terragrunt.hcl
# Root configuration for Terragrunt. This file contains the configuration for the remote state
# backend, which is where Terraform will store the state of your infrastructure.

remote_state {
  backend = "azurerm"
  config = {
    resource_group_name  = "PLEASE_UPDATE" # The name of the resource group where the storage account for the backend is located.
    storage_account_name = "PLEASE_UPDATE" # The name of the storage account.
    container_name       = "tfstate"       # The name of the blob container in the storage account.
    key                  = "${path_relative_to_include()}/terraform.tfstate" # The name of the state file.
  }
}
