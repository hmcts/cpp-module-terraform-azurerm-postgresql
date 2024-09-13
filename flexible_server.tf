resource "azurerm_postgresql_flexible_server" "flexible_server" {
  count               = var.single_server ? 0 : 1
  name                = var.server_name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku_name = var.sku_name

  storage_mb            = var.storage_mb
  storage_tier          = var.storage_tier
  auto_grow_enabled     = var.flexible_auto_grow_enabled
  backup_retention_days = var.backup_retention_days

  administrator_login    = data.vault_generic_secret.administrator_creds.data.administrator_login
  administrator_password = data.vault_generic_secret.administrator_creds.data.administrator_password
  version                = var.server_version

  delegated_subnet_id           = var.delegated_subnet_id
  private_dns_zone_id           = var.private_dns_zone_id
  public_network_access_enabled = var.public_network_access_enabled

  create_mode                       = var.create_mode
  source_server_id                  = var.source_server_id
  point_in_time_restore_time_in_utc = var.point_in_time_restore_time_in_utc

  dynamic "high_availability" {
    for_each = var.create_replica_instance ? [1] : []
    content {
      mode = "ZoneRedundant"
    }
  }

  authentication {
    active_directory_auth_enabled = true
    tenant_id = data.azurerm_client_config.current.tenant_id
    password_auth_enabled = true
  }

  tags = var.tags
  lifecycle {
    ignore_changes = [tags["created_by"], tags["created_time"], zone, high_availability.0.standby_availability_zone]
  }
}

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "example" {
  server_name         = azurerm_postgresql_flexible_server.flexible_server.0.name
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azuread_service_principal.current.object_id
  principal_name      = data.azuread_service_principal.current.display_name
  principal_type      = "ServicePrincipal"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "firewall_rules" {
  count            = var.single_server ? 0 : length(var.firewall_rules)
  name             = format("%s%s", var.firewall_rule_prefix, lookup(var.firewall_rules[count.index], "name", count.index))
  server_id        = local.primary_server_id
  start_ip_address = var.firewall_rules[count.index]["start_ip"]
  end_ip_address   = var.firewall_rules[count.index]["end_ip"]
}

resource "azurerm_postgresql_flexible_server_configuration" "db_configs" {
  for_each  = var.single_server ? {} : var.postgresql_configurations
  server_id = local.primary_server_id

  name  = each.key
  value = each.value
}

resource "azurerm_postgresql_flexible_server_configuration" "db_pgbouncer_config" {
  for_each  = var.single_server ? {} : var.pgbouncer_configurations != null ? var.pgbouncer_configurations : {}
  server_id = local.primary_server_id

  name       = each.key
  value      = each.value
  depends_on = [azurerm_postgresql_flexible_server_configuration.db_configs]
}

resource "azurerm_postgresql_flexible_server_configuration" "db_config_extensions" {
  count     = var.extensions ? 1 : 0
  name      = "azure.extensions"
  server_id = local.primary_server_id
  value     = var.extensions_list
}

resource "azurerm_monitor_diagnostic_setting" "log_to_azure_monitor_flexible" {
  count                      = var.log_to_azure_monitor_flexible.enable && !var.single_server ? 1 : 0
  name                       = "log_to_azure_monitor"
  target_resource_id         = local.primary_server_id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log_analytics_workspace.0.id

  dynamic "log" {
    for_each = var.log_to_azure_monitor_flexible.logs
    content {
      category = log.key
      enabled  = log.value["enabled"]
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = var.log_to_azure_monitor_flexible.all_metrics.enabled
  }
}

resource "azurerm_monitor_metric_alert" "az_postgres_alert_active_connections_flexible" {
  count               = var.enable_monitoring && !var.single_server ? 1 : 0
  name                = "postgres_active_connections_greater_than_dynamic_threshold_${local.primary_server_name}"
  resource_group_name = var.resource_group_name
  scopes              = [local.primary_server_id]
  description         = "Maximum active connections"

  dynamic_criteria {
    metric_namespace  = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name       = "active_connections"
    aggregation       = var.alerts_config_flexible.active_connections.aggregation
    operator          = var.alerts_config_flexible.active_connections.operator
    alert_sensitivity = var.alerts_config_flexible.active_connections.alert_sensitivity
  }
  window_size = "PT5M"
  frequency   = "PT5M"
  action {
    action_group_id = data.azurerm_monitor_action_group.platformDev.0.id
  }
}

resource "azurerm_monitor_metric_alert" "az_postgres_alert_failed_connections_flexible" {
  count               = var.enable_monitoring && !var.single_server ? 1 : 0
  name                = "postgres_failed_connections_greater_than_threshold_${local.primary_server_name}"
  resource_group_name = var.resource_group_name
  scopes              = [local.primary_server_id]
  description         = "Maximum failed connections"

  dynamic_criteria {
    metric_namespace  = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name       = "connections_failed"
    aggregation       = var.alerts_config_flexible.connections_failed.aggregation
    operator          = var.alerts_config_flexible.connections_failed.operator
    alert_sensitivity = var.alerts_config_flexible.connections_failed.alert_sensitivity
  }
  window_size = "PT5M"
  frequency   = "PT5M"
  action {
    action_group_id = data.azurerm_monitor_action_group.platformDev.0.id
  }
}

resource "azurerm_monitor_metric_alert" "az_postgres_alert_cpu_flexible" {
  count               = var.enable_monitoring && !var.single_server ? 1 : 0
  name                = "postgres_cpu_percent_${local.primary_server_name}"
  resource_group_name = var.resource_group_name
  scopes              = [local.primary_server_id]
  description         = "CPU utilization is greater"

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "cpu_percent"
    aggregation      = var.alerts_config_flexible.cpu_percent.aggregation
    operator         = var.alerts_config_flexible.cpu_percent.operator
    threshold        = var.alerts_config_flexible.cpu_percent.threshold
  }
  window_size = "PT5M"
  frequency   = "PT5M"
  action {
    action_group_id = data.azurerm_monitor_action_group.platformDev.0.id
  }
}

resource "azurerm_monitor_metric_alert" "az_postgres_alert_memory_flexible" {
  count               = var.enable_monitoring && !var.single_server ? 1 : 0
  name                = "postgres_memory_percent_${local.primary_server_name}"
  resource_group_name = var.resource_group_name
  scopes              = [local.primary_server_id]
  description         = "Memory utilization"

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "memory_percent"
    aggregation      = var.alerts_config_flexible.memory_percent.aggregation
    operator         = var.alerts_config_flexible.memory_percent.operator
    threshold        = var.alerts_config_flexible.memory_percent.threshold
  }
  window_size = "PT5M"
  frequency   = "PT5M"
  action {
    action_group_id = data.azurerm_monitor_action_group.platformDev.0.id
  }
}

resource "azurerm_monitor_metric_alert" "az_postgres_alert_iops_utilization_flexible" {
  count               = var.enable_monitoring && !var.single_server ? 1 : 0
  name                = "postgres_iops_utilization_${local.primary_server_name}"
  resource_group_name = var.resource_group_name
  scopes              = [local.primary_server_id]
  description         = "IO utilization"

  dynamic_criteria {
    metric_namespace  = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name       = "iops"
    aggregation       = var.alerts_config_flexible.iops.aggregation
    operator          = var.alerts_config_flexible.iops.operator
    alert_sensitivity = var.alerts_config_flexible.iops.alert_sensitivity
  }
  window_size = "PT5M"
  frequency   = "PT5M"
  action {
    action_group_id = data.azurerm_monitor_action_group.platformDev.0.id
  }
}

resource "azurerm_monitor_metric_alert" "az_postgres_alert_storage_utilization_flexible" {
  count               = var.enable_monitoring && !var.single_server ? 1 : 0
  name                = "postgres_storage_utilization_${local.primary_server_name}"
  resource_group_name = var.resource_group_name
  scopes              = [local.primary_server_id]
  description         = "Storage utilization is greater"

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "storage_percent"
    aggregation      = var.alerts_config_flexible.storage_percent.aggregation
    operator         = var.alerts_config_flexible.storage_percent.operator
    threshold        = var.alerts_config_flexible.storage_percent.threshold
  }
  action {
    action_group_id = data.azurerm_monitor_action_group.platformDev.0.id
  }
}

resource "azurerm_monitor_metric_alert" "az_postgres_alert_bloat_percentage" {
  count               = var.enable_bloat_monitoring.enable_bloat_monitoring && !var.single_server ? 1 : 0
  name                = "postgres_bloat_percentage_${local.primary_server_name}"
  resource_group_name = var.resource_group_name
  scopes              = [local.primary_server_id]
  description         = "Bloat percentage is greater"
  severity            = 2

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "bloat_percent"
    aggregation      = var.enable_bloat_monitoring.aggregation
    operator         = var.enable_bloat_monitoring.operator
    threshold        = var.enable_bloat_monitoring.threshold
    dimension {
      name     = "DatabaseName"
      operator = "Exclude"
      values   = var.enable_bloat_monitoring.dbs_to_exclude
    }
  }
  frequency   = var.enable_bloat_monitoring.frequency
  window_size = var.enable_bloat_monitoring.window_size
  action {
    action_group_id = var.action_group_id
  }
}

resource "azurerm_management_lock" "resource_lock" {
  count      = var.create_lock ? 1 : 0
  name       = "lock_${local.primary_server_name}"
  scope      = azurerm_postgresql_flexible_server.flexible_server.0.id
  lock_level = "CanNotDelete"
  notes      = "Locked to prevent accidental deletion"
}
