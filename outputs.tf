output "server_name" {
  description = "The name of the PostgreSQL server"
  value       = local.primary_server_name
}

output "replication_server_name" {
  description = "The name of the PostgreSQL replication server"
  value       = local.replica_single_server_name
}

output "server_fqdn" {
  description = "The fully qualified domain name (FQDN) of the PostgreSQL server"
  value       = local.primary_server_fqdn
}

output "administrator_login" {
  value = var.administrator_login
}

output "server_id" {
  description = "The resource id of the PostgreSQL server"
  value       = local.primary_server_id
}

output "replica_server_id" {
  description = "The resource id of the PostgreSQL replica server - If only single server"
  value       = local.replica_single_server_id
}

# output "database_ids" {
#   description = "The list of all database resource ids"
#   value       = [azurerm_postgresql_database.dbs.*.id]
# }

output "firewall_rule_ids" {
  description = "The list of all firewall rule resource ids"
  value       = [azurerm_postgresql_firewall_rule.firewall_rules.*.id]
}

output "vnet_rule_ids" {
  description = "The list of all vnet rule resource ids"
  value       = [azurerm_postgresql_virtual_network_rule.vnet_rules.*.id]
}

output "sku_name" {
  value = local.sku_name
}

output "storage_mb" {
  value = local.storage_mb
}

output "single_server_configurations" {
  value = tomap({
    for c, config in azurerm_postgresql_configuration.db_configs : c => {
      name  = config.name
      value = config.value
    }
  })
}

output "flexible_server_configurations" {
  value = tomap({
    for c, config in azurerm_postgresql_flexible_server_configuration.db_configs : c => {
      name  = config.name
      value = config.value
    }
  })
}

output "group_list" {
  value = local.group_list
}

output "backup_instance_id" {
  description = "The ID of the backup instance enrollment. Null if backup enrollment is not enabled or conditions not met."
  value       = try(azurerm_data_protection_backup_instance_postgresql_flexible_server.main[0].id, null)
}

output "backup_instance_name" {
  description = "The name of the backup instance enrollment. Null if backup enrollment is not enabled or conditions not met."
  value       = try(azurerm_data_protection_backup_instance_postgresql_flexible_server.main[0].name, null)
}

output "is_enrolled_in_backup_vault" {
  description = "Boolean indicating whether this PostgreSQL server is enrolled in a backup vault for immutable backups."
  value       = local.enable_backup_enrollment
}
