output "server_name" {
  value = values(module.postgresql)[*].server_name
}

output "server_fqdn" {
  value = values(module.postgresql)[*].server_fqdn
}

output "administrator_login" {
  value = values(module.postgresql)[*].administrator_login
}

output "sku_name" {
  value = values(module.postgresql)[*].sku_name
}

output "storage_mb" {
  value = values(module.postgresql)[*].storage_mb
}

output "configurations" {
  value = values(module.postgresql)[*].flexible_server_configurations
}

output "backup_vault_id" {
  description = "ID of the test backup vault (if created)"
  value       = try(azurerm_data_protection_backup_vault.test[0].id, null)
}

output "backup_vault_name" {
  description = "Name of the test backup vault (if created)"
  value       = try(azurerm_data_protection_backup_vault.test[0].name, null)
}

output "backup_instance_ids" {
  description = "IDs of backup instances created for PostgreSQL servers"
  value       = { for k, v in module.postgresql : k => v.backup_instance_id }
}

output "is_enrolled_in_backup_vault" {
  description = "Map of server names to backup enrollment status"
  value       = { for k, v in module.postgresql : k => v.is_enrolled_in_backup_vault }
}
