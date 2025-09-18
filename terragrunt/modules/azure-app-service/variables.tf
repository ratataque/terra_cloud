# variables.tf

variable "project_name" {
  description = "The name of the project."
  type        = string
}

variable "environment" {
  description = "The environment (e.g., dev, staging, prod)."
  type        = string
}

variable "location" {
  description = "The Azure region where the resources will be created."
  type        = string
}

variable "docker_image" {
  description = "The Docker image to deploy."
  type        = string
}

variable "docker_image_tag" {
  description = "The tag of the Docker image to deploy."
  type        = string
  default     = "latest"
}

variable "app_settings" {
  description = "A map of application settings for the App Service."
  type        = map(string)
  default     = {}
}

# Database variables
variable "db_name" {
  description = "The name of the MySQL database to create."
  type        = string
  default     = "laravel"
}

variable "db_admin_username" {
  description = "The admin username for the MySQL server."
  type        = string
}

variable "db_admin_password" {
  description = "The admin password for the MySQL server. Must be complex."
  type        = string
  sensitive   = true
}

# Sizing/SKU variables
variable "app_service_plan_sku" {
  description = "The SKU for the App Service Plan."
  type        = string
  default     = "B1" # Basic tier for non-prod
}

variable "db_sku" {
  description = "The SKU for the MySQL Flexible Server."
  type        = string
  default     = "B_Standard_B1ms" # Burstable tier for non-prod
}
