locals {
  // Assumes var.server_name has the form psf-{env}-ccm{id}-{project}
  // e.g. psf-prd-ccm01-progression
  group_environment_name = upper(split("-", var.server_name)[1])
  group_project          = upper(split("-", var.server_name)[3])
  group_replica_id       = upper(trimprefix(split("-", var.server_name)[2]), "ccm")
  rbac_permissions       = toset(["READ", "DBA", "EDITOR", "ADMIN"])
}

// Groups that grant a specific permission to this specific PGFS instance
resource "azuread_group" "instance_groups" {
  for_each     = local.rbac_permissions
  display_name = "GRP_PGFS_CP_${local.group_environment_name}_${local.group_project}_${local.group_replica_id}_${each.key}"
  mail_enabled = false
}

// Groups that grant a specific permission to all PGFS instances belonging to this project
// Only stood up in PRD CCM01
resource "azuread_group" "common_groups" {
  for_each     = local.group_environment_name == "PRD" && local.group_replica_id == "01" && var.source_server_id == null ? local.rbac_permissions : toset([])
  display_name = "GRP_PGFS_CP_${local.group_project}_${each.key}"
  mail_enabled = false
}
