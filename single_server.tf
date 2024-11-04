resource "azurerm_postgresql_server" "server" {
  count               = var.single_server ? 1 : 0
  name                = var.server_name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku_name = var.sku_name

  storage_mb                   = var.storage_mb
  auto_grow_enabled            = var.auto_grow_enabled
  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  administrator_login              = data.vault_generic_secret.administrator_creds.data.administrator_login
  administrator_login_password     = data.vault_generic_secret.administrator_creds.data.administrator_password
  version                          = var.server_version
  ssl_enforcement_enabled          = var.ssl_enforcement_enabled
  ssl_minimal_tls_version_enforced = var.ssl_minimal_tls_version_enforced
  public_network_access_enabled    = var.public_network_access_enabled

  tags = var.tags
  lifecycle {
    ignore_changes = [tags["created_by"], tags["created_time"]]
  }
}

resource "azurerm_postgresql_server" "server_replica" {
  count               = var.single_server && var.create_replica_instance ? 1 : 0
  name                = "${var.server_name}-replica"
  location            = var.replica_instance_location
  resource_group_name = var.replica_resource_group_name

  sku_name = var.sku_name

  storage_mb                   = var.storage_mb
  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled
  auto_grow_enabled            = var.auto_grow_enabled

  administrator_login              = data.vault_generic_secret.administrator_creds.data.administrator_login
  administrator_login_password     = data.vault_generic_secret.administrator_creds.data.administrator_password
  version                          = var.server_version
  ssl_enforcement_enabled          = var.ssl_enforcement_enabled
  ssl_minimal_tls_version_enforced = var.ssl_minimal_tls_version_enforced
  public_network_access_enabled    = var.public_network_access_enabled

  create_mode               = "Replica"
  creation_source_server_id = azurerm_postgresql_server.server.0.id

  tags = var.tags
  lifecycle {
    ignore_changes = [tags["created_by"], tags["created_time"]]
  }
}

resource "azurerm_postgresql_firewall_rule" "firewall_rules" {
  count               = var.single_server ? length(var.firewall_rules) : 0
  name                = format("%s%s", var.firewall_rule_prefix, lookup(var.firewall_rules[count.index], "name", count.index))
  resource_group_name = var.resource_group_name
  server_name         = local.primary_server_name
  start_ip_address    = var.firewall_rules[count.index]["start_ip"]
  end_ip_address      = var.firewall_rules[count.index]["end_ip"]
}

resource "azurerm_postgresql_virtual_network_rule" "vnet_rules" {
  count               = var.single_server ? length(var.vnet_rules) : 0
  name                = format("%s%s", var.vnet_rule_name_prefix, lookup(var.vnet_rules[count.index], "name", count.index))
  resource_group_name = var.resource_group_name
  server_name         = element(split("/", local.primary_server_id), length(split("/", local.primary_server_id)) - 1)
  subnet_id           = var.vnet_rules[count.index]["subnet_id"]
}

resource "azurerm_postgresql_configuration" "db_configs" {
  for_each            = var.single_server ? var.postgresql_configurations : {}
  resource_group_name = var.resource_group_name
  server_name         = element(split("/", local.primary_server_id), length(split("/", local.primary_server_id)) - 1)

  name  = each.key
  value = each.value
}

resource "azurerm_postgresql_configuration" "db_configs_replica" {
  for_each            = var.single_server && var.create_replica_instance ? var.postgresql_configurations : {}
  resource_group_name = var.replica_resource_group_name
  server_name         = element(split("/", local.replica_single_server_id), length(split("/", local.replica_single_server_id)) - 1)

  name  = each.key
  value = each.value
}

resource "azurerm_monitor_diagnostic_setting" "log_to_azure_monitor_single_primary" {
  count                      = var.log_to_azure_monitor_single_primary.enable && var.single_server ? 1 : 0
  name                       = "log_to_azure_monitor"
  target_resource_id         = local.primary_server_id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log_analytics_workspace.0.id

  enabled_log {
    category = "PostgreSQLLogs"
  }

  enabled_log {
    category = "QueryStoreRuntimeStatistics"
  }

  enabled_log {
    category = "QueryStoreWaitStatistics"
  }

  metric {
    category = "AllMetrics"
    enabled  = var.log_to_azure_monitor_single_primary.all_metrics.enabled
  }
}

resource "azurerm_monitor_diagnostic_setting" "log_to_azure_monitor_single_replica" {
  count                      = var.log_to_azure_monitor_single_replica.enable && var.single_server ? 1 : 0
  name                       = "log_to_azure_monitor"
  target_resource_id         = local.primary_server_id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log_analytics_workspace.0.id

  enabled_log {
    category = "PostgreSQLLogs"
  }

  enabled_log {
    category = "QueryStoreRuntimeStatistics"
  }

  enabled_log {
    category = "QueryStoreWaitStatistics"
  }

  metric {
    category = "AllMetrics"
    enabled  = var.log_to_azure_monitor_single_replica.all_metrics.enabled
  }
}

resource "azurerm_monitor_metric_alert" "az_postgres_alert_active_connections" {
  count               = var.enable_monitoring && var.single_server ? 1 : 0
  name                = "postgres_active_connections_greater_than_80_percent_${local.primary_server_name}"
  resource_group_name = var.resource_group_name
  scopes              = [local.primary_server_id]
  description         = "Whenever the maximum active connections is greater than 80%"

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/servers"
    metric_name      = "active_connections"
    aggregation      = "Average"
    operator         = "GreaterThanOrEqual"
    threshold        = var.sku_name == "GP_Gen5_2" ? 120 : 200
  }
  window_size = "PT30M"
  frequency   = "PT5M"
  action {
    action_group_id = data.azurerm_monitor_action_group.platformDev.0.id
  }
}

resource "azurerm_monitor_metric_alert" "az_postgres_alert_failed_connections" {
  count               = var.enable_monitoring && var.single_server ? 1 : 0
  name                = "postgres_failed_connections_greater_than_10_${local.primary_server_name}"
  resource_group_name = var.resource_group_name
  scopes              = [local.primary_server_id]
  description         = "Whenever the maximum failed connections is greater than 10"

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/servers"
    metric_name      = "connections_failed"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 10
  }
  window_size = "PT30M"
  frequency   = "PT5M"
  action {
    action_group_id = data.azurerm_monitor_action_group.platformDev.0.id
  }
}

resource "azurerm_monitor_metric_alert" "az_postgres_alert_cpu" {
  count               = var.enable_monitoring && var.single_server ? 1 : 0
  name                = "postgres_cpu_percent_95_${local.primary_server_name}"
  resource_group_name = var.resource_group_name
  scopes              = [local.primary_server_id]
  description         = "Whenever the cpu utilization is greater than 95"

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/servers"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 95
  }
  window_size = "PT30M"
  frequency   = "PT5M"
  action {
    action_group_id = data.azurerm_monitor_action_group.platformDev.0.id
  }
}

resource "azurerm_monitor_metric_alert" "az_postgres_alert_memory" {
  count               = var.enable_monitoring && var.single_server ? 1 : 0
  name                = "postgres_memory_percent_95_${local.primary_server_name}"
  resource_group_name = var.resource_group_name
  scopes              = [local.primary_server_id]
  description         = "Whenever the memory utilization is greater than 95"

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/servers"
    metric_name      = "memory_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 95
  }
  window_size = "PT30M"
  frequency   = "PT5M"
  action {
    action_group_id = data.azurerm_monitor_action_group.platformDev.0.id
  }
}

resource "azurerm_monitor_metric_alert" "az_postgres_alert_io_utilization" {
  count               = var.enable_monitoring && var.single_server ? 1 : 0
  name                = "postgres_io_utilization_90_${local.primary_server_name}"
  resource_group_name = var.resource_group_name
  scopes              = [local.primary_server_id]
  description         = "Whenever the io utilization is greater than 90"

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/servers"
    metric_name      = "io_consumption_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 95
  }
  window_size = "PT1H"
  frequency   = "PT5M"
  action {
    action_group_id = data.azurerm_monitor_action_group.platformDev.0.id
  }
}

resource "azurerm_monitor_metric_alert" "az_postgres_alert_storage_utilization" {
  count               = var.enable_monitoring && var.single_server ? 1 : 0
  name                = "postgres_storage_utilization_90_${local.primary_server_name}"
  resource_group_name = var.resource_group_name
  scopes              = [local.primary_server_id]
  description         = "Whenever the storage utilization is greater than 90"

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/servers"
    metric_name      = "storage_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }
  action {
    action_group_id = data.azurerm_monitor_action_group.platformDev.0.id
  }
}

resource "azurerm_monitor_metric_alert" "az_postgres_alert_replica_lag" {
  count               = var.enable_monitoring && var.create_replica_instance && var.single_server ? 1 : 0
  name                = "postgres_replica_lag_1minute_${local.primary_server_name}"
  resource_group_name = var.resource_group_name
  scopes              = [local.primary_server_id]
  description         = "Whenever the replica lag is greater than 1 minute"

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/servers"
    metric_name      = "pg_replica_log_delay_in_seconds"
    aggregation      = "Maximum"
    operator         = "GreaterThan"
    threshold        = 60
  }
  window_size = "PT15M"
  action {
    action_group_id = data.azurerm_monitor_action_group.platformDev.0.id
  }
}
