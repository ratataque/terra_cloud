include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../modules/azure-app-service"
}

inputs = {
  project_name = "terracloud"
  environment  = "prod"
  location     = "westeurope"

  tags = {
    Environment = "Production"
    CostCenter  = "Engineering"
  }

  app_service_plan_sku = "P1v3"
  acr_sku              = "Standard"

  db_name           = "terracloud_prod"
  db_admin_username = "sqladmin"
  db_admin_password = get_env("DB_ADMIN_PASSWORD")
  db_sku            = "GP_Standard_D2ds_v4"
  db_storage_gb     = 100

  docker_image     = "terracloudprodacr.azurecr.io/app"
  docker_image_tag = get_env("DOCKER_TAG", "stable")

  app_settings = {
    "APP_NAME"    = "TerraCloud"
    "APP_ENV"     = "production"
    "APP_KEY"     = get_env("APP_KEY")
    "APP_DEBUG"   = "false"
    "APP_URL"     = "https://terracloud-prod-app.azurewebsites.net"
    "LOG_CHANNEL" = "stack"
    "LOG_LEVEL"   = "warning"
    "CACHE_DRIVER" = "redis"
    "SESSION_DRIVER" = "redis"
  }
}
