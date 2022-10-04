resource "random_password" "administrator_password" {
  length           = 24
  number           = true
  special          = true
  override_special = "!%&*()-_=+[]{}<>:?"
}

resource "vault_generic_secret" "administrator_creds" {
  path = var.administrator_creds_vault_path

  data_json = <<EOT
{
  "administrator_login": "${var.administrator_login}",
  "administrator_password": "${random_password.administrator_password.result}"
}
EOT

  depends_on = [random_password.administrator_password]
}

data "vault_generic_secret" "administrator_creds" {
  path       = var.administrator_creds_vault_path
  depends_on = [vault_generic_secret.administrator_creds]
}

data "azurerm_monitor_action_group" "platformDev" {
  count               = var.action_group_enable_data_lookup ? 1 : 0
  name                = var.action_group_name
  resource_group_name = var.actiongroup_resource_group_name
}

data "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  count               = var.log_analytics_workspace_enable_data_lookup ? 1 : 0
  name                = var.log_analytics_workspace_name
  resource_group_name = var.log_analytics_workspace_resource_group_name
}

locals {
  primary_server_name        = var.single_server ? join(", ", azurerm_postgresql_server.server.*.name) : join(", ", azurerm_postgresql_flexible_server.flexible_server.*.name)
  primary_server_id          = var.single_server ? join(", ", azurerm_postgresql_server.server.*.id) : join(", ", azurerm_postgresql_flexible_server.flexible_server.*.id)
  replica_single_server_name = join(", ", azurerm_postgresql_server.server_replica.*.name)
  replica_single_server_id   = join(", ", azurerm_postgresql_server.server_replica.*.id)
  primary_server_fqdn        = var.single_server ? join(", ", azurerm_postgresql_server.server.*.fqdn) : join(", ", azurerm_postgresql_flexible_server.flexible_server.*.fqdn)
  sku_name                   = var.single_server ? join(", ", azurerm_postgresql_server.server.*.sku_name) : join(", ", azurerm_postgresql_flexible_server.flexible_server.*.sku_name)
  storage_mb                 = var.single_server ? join(", ", azurerm_postgresql_server.server.*.storage_mb) : join(", ", azurerm_postgresql_flexible_server.flexible_server.*.storage_mb)
}

# resource "azurerm_postgresql_database" "dbs" {
#   count               = length(var.db_names)
#   name                = var.db_names[count.index]
#   resource_group_name = var.resource_group_name
#   server_name         = azurerm_postgresql_server.server.name
#   charset             = var.db_charset
#   collation           = var.db_collation
# }
