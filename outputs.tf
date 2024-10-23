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

#output "rbac" {
#  value = var.rbac
#}
