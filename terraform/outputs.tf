output "bastion_public_ip" {
  value       = vkcs_networking_floatingip.bastion.address
  description = "Bastion host public IP for SSH access"
}

output "bastion_private_ip" {
  value       = vkcs_compute_instance.bastion.access_ip_v4
  description = "Bastion private IP"
}

output "load_balancer_public_ip" {
  value       = vkcs_networking_floatingip.lb.address
  description = "Load balancer public IP"
}

output "web_servers_private_ips" {
  value       = vkcs_compute_instance.web[*].access_ip_v4
  description = "Web servers private IPs"
}

output "db_host" {
  value       = vkcs_db_instance.main.ip
  description = "Database private IP"
}

output "db_name" {
  value       = vkcs_db_database.app.name
  description = "Database name"
}

output "db_user" {
  value       = vkcs_db_user.app.name
  description = "Database user"
}

output "db_password_file" {
  value       = "${path.module}/db_password.txt"
  description = "File with database password"
}