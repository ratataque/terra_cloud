# terragrunt.hcl (prod environment)
# This file contains the configuration for the 'prod' environment.

include {
  path = find_in_parent_folders()
}

terraform {
  source = "../modules/azure-app-service"
}

# These are the inputs we'll pass to our Terraform module.
# You can override these values in a terraform.tfvars file.
inputs = {
  # Naming and location
  project_name = "sampleapp"
  environment  = "prod"
  location     = "West Europe"

  # Production SKUs for App Service Plan and Database
  app_service_plan_sku = "S1" # Standard tier for production
  db_sku               = "GP_Standard_D2ds_v4" # General Purpose tier for production

  # Database credentials (set password in terraform.tfvars)
  db_name           = "sampleapp_prod"
  db_admin_username = "dbadmin"
  db_admin_password = "" # MUST be set in terraform.tfvars

  # Docker Image Details (update after pushing your image to ACR)
  docker_image     = "sampleapp.azurecr.io/sample-app" # This will be updated with your ACR login server
  docker_image_tag = "latest"

  # App Service Environment Variables
  # Non-sensitive settings for your application.
  # DB settings are now configured automatically from the database resource.
  app_settings = {
    "APP_NAME"    = "Laravel"
    "APP_ENV"     = "production"
    "APP_KEY"     = "base64:YOUR_APP_KEY" # IMPORTANT: Generate a new key with `php artisan key:generate --show`
    "APP_DEBUG"   = "false"
    "APP_URL"     = "http://localhost"
    "LOG_CHANNEL" = "stack"
  }
}
