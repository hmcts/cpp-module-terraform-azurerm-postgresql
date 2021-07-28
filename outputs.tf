output "server_name" {
  description = "The name of the PostgreSQL server"
  value       = azurerm_postgresql_server.server.name
}

output "replication_server_name" {
  description = "The name of the PostgreSQL replication server"
  value       = azurerm_postgresql_server.server_replica.*.name
}

output "server_fqdn" {
  description = "The fully qualified domain name (FQDN) of the PostgreSQL server"
  value       = azurerm_postgresql_server.server.fqdn
}

output "replica_server_fqdn" {
  description = "The fully qualified domain name (FQDN) of the PostgreSQL server"
  value       = azurerm_postgresql_server.server_replica.*.fqdn
}

output "administrator_login" {
  value = var.administrator_login
}

output "server_id" {
  description = "The resource id of the PostgreSQL server"
  value       = azurerm_postgresql_server.server.id
}

output "replica_server_id" {
  description = "The resource id of the PostgreSQL server"
  value       = azurerm_postgresql_server.server_replica.*.id
}

output "database_ids" {
  description = "The list of all database resource ids"
  value       = [azurerm_postgresql_database.dbs.*.id]
}

output "firewall_rule_ids" {
  description = "The list of all firewall rule resource ids"
  value       = [azurerm_postgresql_firewall_rule.firewall_rules.*.id]
}

output "vnet_rule_ids" {
  description = "The list of all vnet rule resource ids"
  value       = [azurerm_postgresql_virtual_network_rule.vnet_rules.*.id]
}

output "private_endpoint_id" {
  description = "private endpoint primary instance ID"
  value       = azurerm_private_endpoint.private_endpoint.*.id
}

output "private_endpoint_ip_address" {
  description = "private endpoint private IP address"
  value       = azurerm_private_endpoint.private_endpoint.*.private_service_connection
}

output "replica_private_endpoint_id" {
  description = "private endpoint replica instance ID"
  value       = azurerm_private_endpoint.private_endpoint_replica.*.id
}

output "replica_private_endpoint_ip_address" {
  description = "replica private endpoint private IP address"
  value       = azurerm_private_endpoint.private_endpoint_replica.*.private_service_connection
}