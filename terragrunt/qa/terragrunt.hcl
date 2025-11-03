include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../modules/azure-app-service"
}

inputs = {
  project_name = "terracloud"
  environment  = "qa"
  location     = "westeurope"

  tags = {
    Environment = "QA"
    CostCenter  = "Engineering"
  }

  app_service_plan_sku = "B2"
  acr_sku              = "Basic"

  db_name           = "terracloud_qa"
  db_admin_username = "dbadmin"
  db_admin_password = get_env("DB_ADMIN_PASSWORD")
  db_sku            = "B_Standard_B2s"
  db_storage_gb     = 20

  docker_image     = "terracloudqaacr.azurecr.io/app"
  docker_image_tag = get_env("DOCKER_TAG", "latest")

  app_settings = {
    "APP_NAME"    = "TerraCloud"
    "APP_ENV"     = "qa"
    "APP_KEY"     = get_env("APP_KEY")
    "APP_DEBUG"   = "true"
    "APP_URL"     = "https://terracloud-qa-app.azurewebsites.net"
    "LOG_CHANNEL" = "stack"
    "LOG_LEVEL"   = "debug"
  }
}
