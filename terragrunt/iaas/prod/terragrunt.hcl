include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../modules/azure-iaas-app-service"
}

dependency "shared" {
  config_path = "../../shared"
}

inputs = {
  resource_group_name = include.root.locals.resource_group_name
  project_name        = include.root.locals.project_name
  environment         = "prod"
  location            = include.root.locals.location
  vm_size             = "Standard_B1ls"

  tags = merge(
    include.root.locals.common_tags,
    {
      Environment = "Production"
    }
  )

  # VM Configuration (remplace App Service Plan du PaaS)
  vm_size  = "Standard_D2s_v3"  # Taille de la VM : 2 vCPUs, 8 GB RAM (plus puissant pour prod)
  vm_count = 3                  # 3 VMs pour meilleure haute disponibilité en production
#enable_load_balancer = true   # Load Balancer activé pour distribuer le trafic entre les 3 VMs
  
  # Clé SSH pour accéder aux VMs (vous devez générer une clé SSH)
  ssh_public_key = get_env("SSH_PUBLIC_KEY", "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDVwROl8+8GisBEd0K5czNJyASqTeZhTZVlwqP9qZW/hppzyF3Z9xjsQM9ixwfnLxpu3djis+kejFcnGVv6/D+6L7ZBqcn6VfX2xhwSSTOh0D5zIzzSHF6yANs7IInCDVDB+pSAHdss+L185vni+a9s11E9aQ6+1qzCjPAE2sKMECmYTSB7OYP7NZNc/r31jKFEygU/MRnWR2VJmJKrnCwysEQE6j167CEMAOeHfIxAthNQPZtu12aqy3qVx38gyHPsrECGFIBtKbwwdbioYzyMarolTCOyppgJmwtC7yGFg0O+8Nk+Ce5J2T+BiM8JW9wu9ijnmDi2/Fqz5+CvW2P0QSWDXg5Ctsq+d41KNpjqBzKJs5eNouYhIsujzMbBFRcSPndkmq29TdTbefteYpdvwKggRUCE3DJOvv5YeekLe/S2G3j63mUvQBZPEfn9hcHGqlk2sNYGw+pP5B2iijlOQYgcev6Lx5JbLOerF+B+KFpKrg71IIvSnAB998MLsX5nL0L/ypqnoFT8++1gM22FDoDqZ1B8TIb0HcDnFZktrEm1SCRp1QUyIiutNW6F7J5lE9QHvLL/WQKgwuxHAPgWfoC3M5nrh2klE4Wbsjh9hBRv7WjlRrVbxJynWaHyosuoooNpZhynvP+LkKu0YwNk2kyAOF3ykkFyWbdpy77GEw== ahmed.basabaien@epitech.eu")

  # Reference shared ACR
  acr_login_server    = dependency.shared.outputs.acr_login_server
  acr_admin_username  = dependency.shared.outputs.acr_admin_username
  acr_admin_password  = dependency.shared.outputs.acr_admin_password
  acr_id              = dependency.shared.outputs.acr_id

  db_name           = "terracloud_prod"
  db_admin_username = "sqladmin"
  db_admin_password = include.root.locals.db_admin_password
  db_sku            = "B_Standard_B1ms"
  db_storage_gb     = 100

  docker_image     = "${dependency.shared.outputs.acr_login_server}/${include.root.locals.docker_image_base}"
  docker_image_tag = get_env("DOCKER_TAG", "stable")

  app_settings = merge(
    include.root.locals.common_app_settings,
    {
      "APP_ENV"       = "production"
      "APP_DEBUG"     = "false"
      "APP_URL"       = "http://load-balancer-ip"  # Sera remplacé par l'IP du Load Balancer après déploiement
      "LOG_LEVEL"     = "warning"
      "CACHE_DRIVER"  = "redis"
      "SESSION_DRIVER" = "redis"
    }
  )
}
