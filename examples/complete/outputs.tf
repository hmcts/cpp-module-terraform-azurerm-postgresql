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
