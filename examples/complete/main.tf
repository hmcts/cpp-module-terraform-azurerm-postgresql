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
  count    = var.private_dns_config.enable_data_lookup ? 0 : 1
  name     = format("test-mdv-%s", random_id.name.hex)
  location = var.location
}

resource "azurerm_private_dns_zone" "dns" {
  count               = var.private_dns_config.enable_data_lookup ? 0 : 1
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.dns[0].name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns-vn-link" {
  count                 = var.private_dns_config.enable_data_lookup ? 0 : 1
  name                  = "postgres-vn-link"
  resource_group_name   = azurerm_resource_group.dns[0].name
  private_dns_zone_name = azurerm_private_dns_zone.dns[0].name
  virtual_network_id    = data.azurerm_virtual_network.vnet.id
}

resource "azurerm_resource_group" "backup" {
  count    = var.enable_immutable_backups ? 1 : 0
  name     = format("test-backup-%s", random_id.name.hex)
  location = var.location
}

resource "azurerm_data_protection_backup_vault" "test" {
  count               = var.enable_immutable_backups ? 1 : 0
  name                = format("backup-vault-test-%s", random_id.name.hex)
  resource_group_name = azurerm_resource_group.backup[0].name
  location            = var.location
  datastore_type      = "VaultStore"
  redundancy          = "LocallyRedundant"

  soft_delete                = "Off"
  retention_duration_in_days = 14

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_data_protection_backup_policy_postgresql_flexible_server" "test" {
  count    = var.enable_immutable_backups ? 1 : 0
  name     = "postgresql-test"
  vault_id = azurerm_data_protection_backup_vault.test[0].id

  # Weekly backup schedule (Sunday at 03:00 UTC) - matches production test policy
  backup_repeating_time_intervals = ["R/2024-01-07T03:00:00+00:00/P1W"]
  time_zone                       = "UTC"

  # Minimal retention - 1 week for testing purposes
  default_retention_rule {
    life_cycle {
      duration        = "P7D"
      data_store_type = "VaultStore"
    }
  }
}

# Wait for RBAC propagation before the module creates the backup instance
resource "time_sleep" "wait_for_backup_vault" {
  count           = var.enable_immutable_backups ? 1 : 0
  create_duration = "60s"

  depends_on = [
    azurerm_data_protection_backup_vault.test,
    azurerm_data_protection_backup_policy_postgresql_flexible_server.test
  ]
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
  private_dns_zone_id                         = var.private_dns_config.enable_data_lookup ? data.azurerm_private_dns_zone.private_dns_zone_id[0].id : azurerm_private_dns_zone.dns[0].id
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
  logfiles_download_enable                    = var.logfiles_download_enable
  logfiles_retention_days                     = var.logfiles_retention_days
  alerts_config_flexible                      = var.alerts_config_flexible
  action_group_enable_data_lookup             = var.action_group_enable_data_lookup
  log_analytics_workspace_enable_data_lookup  = var.log_analytics_workspace_enable_data_lookup
  create_lock                                 = var.create_lock
  entra_admin_user                            = var.entra_admin_user
  entra_admin_pwd                             = "test"
  admin_password_special_char                 = var.admin_password_special_char
  maintenance_window                          = var.maintenance_window

  # Backup vault configuration (created above for testing)
  service_criticality         = var.service_criticality
  enable_immutable_backups    = var.enable_immutable_backups
  backup_vault_name           = var.enable_immutable_backups ? azurerm_data_protection_backup_vault.test[0].name : null
  backup_vault_resource_group = var.enable_immutable_backups ? azurerm_resource_group.backup[0].name : null
  backup_policy_name          = var.enable_immutable_backups ? azurerm_data_protection_backup_policy_postgresql_flexible_server.test[0].name : null

  depends_on = [
    azurerm_resource_group.test,
    azurerm_data_protection_backup_vault.test,
    azurerm_data_protection_backup_policy_postgresql_flexible_server.test,
    time_sleep.wait_for_backup_vault
  ]
}
