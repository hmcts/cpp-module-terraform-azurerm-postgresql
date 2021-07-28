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

resource "azurerm_postgresql_server" "server" {
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
}

resource "azurerm_postgresql_server" "server_replica" {
  count               = var.create_replica_instance ? 1 : 0
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
  creation_source_server_id = azurerm_postgresql_server.server.id

  tags = var.tags
}


resource "azurerm_postgresql_database" "dbs" {
  count               = length(var.db_names)
  name                = var.db_names[count.index]
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.server.name
  charset             = var.db_charset
  collation           = var.db_collation
}

resource "azurerm_postgresql_firewall_rule" "firewall_rules" {
  count               = length(var.firewall_rules)
  name                = format("%s%s", var.firewall_rule_prefix, lookup(var.firewall_rules[count.index], "name", count.index))
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.server.name
  start_ip_address    = var.firewall_rules[count.index]["start_ip"]
  end_ip_address      = var.firewall_rules[count.index]["end_ip"]
}

resource "azurerm_postgresql_virtual_network_rule" "vnet_rules" {
  count               = length(var.vnet_rules)
  name                = format("%s%s", var.vnet_rule_name_prefix, lookup(var.vnet_rules[count.index], "name", count.index))
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.server.name
  subnet_id           = var.vnet_rules[count.index]["subnet_id"]
}

resource "azurerm_postgresql_configuration" "db_configs" {
  count               = length(keys(var.postgresql_configurations))
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.server.name

  name  = element(keys(var.postgresql_configurations), count.index)
  value = element(values(var.postgresql_configurations), count.index)
}

resource "azurerm_private_endpoint" "private_endpoint" {
  count               = var.private_endpoint_enabled ? 1 : 0
  name                = "${var.private_endpoint_name_prefix}-${azurerm_postgresql_server.server.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.private_service_connection_name_prefix}-${azurerm_postgresql_server.server.name}"
    private_connection_resource_id = azurerm_postgresql_server.server.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = var.private_service_connection_is_manual
  }

  private_dns_zone_group {
    name                 = var.privatelink_dns_zone_group_name
    private_dns_zone_ids = [var.privatelink_dns_zone_id]
  }
}


resource "azurerm_private_endpoint" "private_endpoint_replica" {
  count               = var.private_endpoint_enabled && var.create_replica_instance ? 1 : 0
  name                = "${var.private_endpoint_name_prefix}-${azurerm_postgresql_server.server_replica[0].name}"
  location            = var.replica_instance_location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_replica_subnet_id

  private_service_connection {
    name                           = "${var.private_service_connection_name_prefix}-${azurerm_postgresql_server.server_replica[0].name}"
    private_connection_resource_id = azurerm_postgresql_server.server_replica[0].id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = var.private_service_connection_is_manual
  }

  private_dns_zone_group {
    name                 = var.privatelink_dns_zone_group_name
    private_dns_zone_ids = [var.privatelink_dns_zone_id]
  }
}
# resource "azurerm_private_dns_cname_record" "server_name_cname_record" {
#   name                = var.server_name
#   zone_name           = var.privatelink_dns_zone_name
#   resource_group_name = var.privatelink_dns_zone_rg_name
#   ttl                 = var.dns_cname_ttl
#   record              = "${azurerm_postgresql_server.server.name}.${var.privatelink_dns_zone_name}"

#   depends_on = [azurerm_postgresql_server.server]
# }