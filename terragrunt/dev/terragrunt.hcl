# terragrunt.hcl (dev environment)
# This file contains the configuration for the 'dev' environment.

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
  environment  = "dev"
  location     = "West Europe" # Example: "East US", "West Europe"

  # Docker Image Details (update after pushing your image to ACR)
  docker_image          = "sampleapp.azurecr.io/sample-app" # This will be updated with your ACR login server
  docker_image_tag      = "latest"

  # App Service Environment Variables
  # Add any environment variables your Laravel application needs.
  # These will be securely passed to your App Service.
  app_settings = {
    "APP_NAME"          = "Laravel"
    "APP_ENV"           = "production"
    "APP_KEY"           = "base64:YOUR_APP_KEY" # IMPORTANT: Generate a new key with `php artisan key:generate --show`
    "APP_DEBUG"         = "false"
    "APP_URL"           = "http://localhost"
    "LOG_CHANNEL"       = "stack"
    "DB_CONNECTION"     = "mysql"
    "DB_HOST"           = "127.0.0.1"
    "DB_PORT"           = "3306"
    "DB_DATABASE"       = "laravel"
    "DB_USERNAME"       = "root"
    "DB_PASSWORD"       = ""
  }
}
