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
