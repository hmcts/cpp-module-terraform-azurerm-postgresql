# AzureRM 4.x Migration

## Changes Applied

- Constrained AzureRM to `>= 4.0.0, < 5.0.0` in the module and complete example.
- Raised the Terraform minimum to 1.7 for non-destructive group ownership removal.
- Synced main's group-name calculation and stopped managing instance Entra groups
  using a `removed` block with `destroy = false`. Removed the stale RBAC dependency.
- Restored the nine caller inputs present on the main branch: `logfiles_download_enable`,
  `logfiles_retention_days`, `entra_db_project_specific_groups`,
  `admin_password_special_char`, `maintenance_window`, `service_criticality`,
  `backup_policy_name`, `backup_vault_name`, and `backup_vault_resource_group`.
- Wired downloadable logs, password special characters, and maintenance windows to
  their resources. The password option defaults to `true`, preserving this branch's behavior.
- Ported backup enrollment and its outputs from main. Flexible Servers with
  criticality 4 or 5 require all three backup inputs. Lower criticalities do not enroll.
- Kept the AzureRM 4.x `enabled_log` block, corrected its iterator, and excluded
  disabled log categories.
- Retained numeric password characters through the Random provider's default,
  compatible with both the example's pinned 3.1.0 and current versions.
- Updated the complete example to exercise all nine module arguments.

## Deployment Requirements

The reported unsupported arguments were missing module variables, not removed
AzureRM resource arguments. Callers must use the module revision containing these
changes. Updating a provider constraint alone does not update a Git module source;
update its ref and reinitialize the calling configuration.

AzureRM 4.x requires `subscription_id` in the root provider configuration or
`ARM_SUBSCRIPTION_ID` in the environment. This module does not configure credentials.

The project-specific Entra groups input is retained for compatibility with main.
As on main, it does not create groups or grant database access. `entra_db_groups`
still controls database role setup, but no longer creates Entra groups. Existing
instance groups tracked by this module are forgotten on apply, not deleted from
Azure. Groups must exist and be managed outside this module before database setup.

Backup vaults and policies must already exist. The vault identity must have Reader
on the PostgreSQL resource group, managed outside this module. This module grants
the PostgreSQL Flexible Server Long Term Retention Backup Role on the server.
Vault immutability is controlled outside this module; enrollment does not enable it.
Immutable vaults may prevent deletion of backup instances while recovery points exist.

Existing Flexible Server resource addresses are unchanged. If the log configuration
resources already exist in state from main, Terraform should automatically move
their unindexed addresses to `[0]` when adding `count`; verify that the plan shows
moves rather than replacements. This change does not migrate database data or
Single Server state. Single Server resources remain deprecated in AzureRM 4.x and
are not supported by the retired Azure service for new deployments. Do not apply
against existing infrastructure without reviewing the complete caller plan.

## References

- [AzureRM 4.0 upgrade guide](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide)
- [PostgreSQL Flexible Server backup instance](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/data_protection_backup_instance_postgresql_flexible_server)