locals {
  enable_backup_enrollment = var.service_criticality >= 4 && !var.single_server
  backup_policy_id         = local.enable_backup_enrollment ? "${data.azurerm_data_protection_backup_vault.vault[0].id}/backupPolicies/${var.backup_policy_name}" : null
}

data "azurerm_data_protection_backup_vault" "vault" {
  count               = local.enable_backup_enrollment ? 1 : 0
  name                = var.backup_vault_name
  resource_group_name = var.backup_vault_resource_group

  lifecycle {
    precondition {
      condition     = var.backup_vault_name != null && var.backup_vault_resource_group != null && var.backup_policy_name != null
      error_message = "backup_vault_name, backup_vault_resource_group, and backup_policy_name must be provided when service_criticality >= 4."
    }
  }
}

resource "azurerm_role_assignment" "backup_vault_postgres_ltr" {
  count                = local.enable_backup_enrollment ? 1 : 0
  scope                = local.primary_server_id
  role_definition_name = "PostgreSQL Flexible Server Long Term Retention Backup Role"
  principal_id         = data.azurerm_data_protection_backup_vault.vault[0].identity[0].principal_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_data_protection_backup_instance_postgresql_flexible_server" "main" {
  count            = local.enable_backup_enrollment ? 1 : 0
  name             = "${var.server_name}-backup-instance"
  location         = var.location
  vault_id         = data.azurerm_data_protection_backup_vault.vault[0].id
  server_id        = local.primary_server_id
  backup_policy_id = local.backup_policy_id

  depends_on = [
    azurerm_role_assignment.backup_vault_postgres_ltr,
    azurerm_postgresql_flexible_server.flexible_server
  ]
}
