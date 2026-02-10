locals {
  # Determine if backup enrollment should be created
  enable_backup_enrollment = var.enable_immutable_backups && var.service_criticality >= 4 && !var.single_server

  # Construct backup policy ID from vault ID and policy name
  backup_policy_id = local.enable_backup_enrollment ? "${data.azurerm_data_protection_backup_vault.vault[0].id}/backupPolicies/${var.backup_policy_name}" : null
}

data "azurerm_resource_group" "main" {
  count = local.enable_backup_enrollment ? 1 : 0
  name  = var.resource_group_name
}

data "azurerm_data_protection_backup_vault" "vault" {
  count               = local.enable_backup_enrollment ? 1 : 0
  name                = var.backup_vault_name
  resource_group_name = var.backup_vault_resource_group
}

resource "azurerm_role_assignment" "backup_vault_reader" {
  count                = local.enable_backup_enrollment ? 1 : 0
  scope                = data.azurerm_resource_group.main[0].id
  role_definition_name = "Reader"
  principal_id         = data.azurerm_data_protection_backup_vault.vault[0].identity[0].principal_id

  # Prevent role assignment from being destroyed before backup instance
  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_role_assignment" "backup_vault_postgres_ltr" {
  count                = local.enable_backup_enrollment ? 1 : 0
  scope                = local.primary_server_id
  role_definition_name = "PostgreSQL Flexible Server Long Term Retention Backup Role"
  principal_id         = data.azurerm_data_protection_backup_vault.vault[0].identity[0].principal_id

  # Prevent role assignment from being destroyed before backup instance
  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_data_protection_backup_instance_postgresql_flexible_server" "main" {
  count    = local.enable_backup_enrollment ? 1 : 0
  name     = "${var.server_name}-backup-instance"
  location = var.location

  vault_id         = data.azurerm_data_protection_backup_vault.vault[0].id
  server_id        = local.primary_server_id
  backup_policy_id = local.backup_policy_id

  # Ensure RBAC permissions are in place before attempting enrollment
  # Without these, enrollment will fail with "Unauthorized" error
  depends_on = [
    azurerm_role_assignment.backup_vault_reader,
    azurerm_role_assignment.backup_vault_postgres_ltr,
    azurerm_postgresql_flexible_server.flexible_server
  ]
}
