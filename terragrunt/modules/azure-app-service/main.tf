terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

# Create a resource group
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location
}

# Create an Azure Container Registry
resource "azurerm_container_registry" "main" {
  name                = "${var.project_name}${var.environment}acr"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true
}

# Create a flexible MySQL server
resource "azurerm_mysql_flexible_server" "main" {
  name                   = "${var.project_name}-${var.environment}-mysql"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  administrator_login    = var.db_admin_username
  administrator_password = var.db_admin_password
  sku_name               = "B_Standard_B1ms" # Burstable, good for dev/test
  version                = "8.0.21"

  # Allow public access from any Azure service
  public_network_access_enabled = true
}

# Create a database within the flexible server
resource "azurerm_mysql_flexible_database" "main" {
  name                = var.db_name
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.main.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

# Create an App Service Plan
resource "azurerm_service_plan" "main" {
  name                = "${var.project_name}-${var.environment}-asp"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = var.app_service_plan_sku
}

# Create a Linux Web App for containers
resource "azurerm_linux_web_app" "main" {
  name                = "${var.project_name}-${var.environment}-app"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_service_plan.main.location
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    application_stack {
      docker_image     = var.docker_image
      docker_image_tag = var.docker_image_tag
    }
  }

  app_settings = merge(var.app_settings, {
    "DB_CONNECTION" = "mysql"
    "DB_HOST"       = azurerm_mysql_flexible_server.main.fqdn
    "DB_PORT"       = "3306"
    "DB_DATABASE"   = azurerm_mysql_flexible_database.main.name
    "DB_USERNAME"   = azurerm_mysql_flexible_server.main.administrator_login
    "DB_PASSWORD"   = azurerm_mysql_flexible_server.main.administrator_password
  })

  identity {
    type = "SystemAssigned"
  }
}

# Grant the App Service pull access to the Container Registry
resource "azurerm_role_assignment" "app_to_acr" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.main.identity[0].principal_id
}
