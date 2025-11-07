output "resource_group_name" {
  description = "The name of the resource group"
  value       = data.azurerm_resource_group.main.name
}

output "load_balancer_public_ip" {
  description = "The public IP address of the load balancer"
  value       = azurerm_public_ip.lb.ip_address
}

output "load_balancer_url" {
  description = "The URL to access the application"
  value       = "http://${azurerm_public_ip.lb.ip_address}"
}

output "vm_names" {
  description = "The names of the virtual machines"
  value       = azurerm_linux_virtual_machine.vm[*].name
}

output "vm_private_ips" {
  description = "The private IP addresses of the virtual machines"
  value       = azurerm_network_interface.vm[*].private_ip_address
}

output "database_host" {
  description = "The FQDN of the MySQL Flexible Server"
  value       = azurerm_mysql_flexible_server.main.fqdn
}

output "database_name" {
  description = "The name of the database"
  value       = azurerm_mysql_flexible_database.main.name
}

output "vnet_name" {
  description = "The name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "subnet_id" {
  description = "The ID of the application subnet"
  value       = azurerm_subnet.app.id
}
