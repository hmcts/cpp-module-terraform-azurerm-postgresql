resource "random_id" "name" {
  byte_length = 8
}

resource "azurerm_resource_group" "test" {
  name     = format("test-postgressql-%s", random_id.name.hex)
  location = var.location
}

resource "azurerm_resource_group" "testreplica" {
  name     = format("test-postgressql-replica-%s", random_id.name.hex)
  location = var.location
}

resource "azurerm_resource_group" "dns" {
  name     = format("test-mdv-%s", random_id.name.hex)
  location = var.location
}

resource "azurerm_private_dns_zone" "dns" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.dns.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns-vn-link" {
  name                  = "postgres-vn-link"
  resource_group_name   = azurerm_resource_group.dns.name
  private_dns_zone_name = azurerm_private_dns_zone.dns.name
  virtual_network_id    = data.azurerm_virtual_network.vnet.id
}

module "postgresql" {
  for_each = { for instance in var.psql_instances : instance.server_name => instance }
  source   = "../../"

  resource_group_name                         = azurerm_resource_group.test.name
  replica_resource_group_name                 = azurerm_resource_group.testreplica.name
  location                                    = var.location
  server_name                                 = each.value.server_name
  sku_name                                    = each.value.sku_name
  storage_mb                                  = each.value.storage_mb
  storage_tier                                = each.value.storage_tier
  backup_retention_days                       = each.value.backup_retention_days
  geo_redundant_backup_enabled                = each.value.geo_redundant_backup_enabled
  administrator_login                         = "pgsqladmin"
  administrator_creds_azkv_secret_name        = "test"
  administrator_creds_vault_path              = "/secret/mgmt/${each.value.server_name}-creds"
  server_version                              = each.value.server_version
  postgresql_configurations                   = each.value.postgresql_configurations
  extensions                                  = each.value.extensions
  single_server                               = each.value.single_server
  delegated_subnet_id                         = var.subnet_config.enable_data_lookup ? data.azurerm_subnet.delegated_subnet_id.0.id : null
  private_dns_zone_id                         = azurerm_private_dns_zone.dns.id
  ssl_enforcement_enabled                     = true
  public_network_access_enabled               = false
  create_replica_instance                     = each.value.create_replica_instance
  firewall_rules                              = each.value.firewall_rules
  replica_instance_location                   = var.replica_instance_location
  vnet_rules                                  = []
  tags                                        = var.tags
  enable_monitoring                           = var.enable_monitoring
  actiongroup_resource_group_name             = var.actiongroup_resource_group_name
  log_analytics_workspace_name                = var.log_analytics_workspace_name
  log_analytics_workspace_resource_group_name = var.log_analytics_workspace_resource_group_name
  log_to_azure_monitor_single_primary         = var.log_to_azure_monitor_single_primary
  log_to_azure_monitor_single_replica         = var.log_to_azure_monitor_single_replica
  log_to_azure_monitor_flexible               = var.log_to_azure_monitor_flexible
  alerts_config_flexible                      = var.alerts_config_flexible
  action_group_enable_data_lookup             = var.action_group_enable_data_lookup
  log_analytics_workspace_enable_data_lookup  = var.log_analytics_workspace_enable_data_lookup
  create_lock                                 = var.create_lock
  entra_admin_user                            = var.entra_admin_user

  depends_on = [
    azurerm_resource_group.test,
    azurerm_private_dns_zone.dns,
    azurerm_private_dns_zone_virtual_network_link.dns-vn-link
  ]
}
