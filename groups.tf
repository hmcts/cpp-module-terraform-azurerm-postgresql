locals {
  // Assumes var.server_name has the form "psf-{env}-ccm{id}-{project}"
  // e.g. psf-prd-ccm01-progression
  // May break for replicas
  server_name_array      = split("-", var.server_name)
  group_environment_name = upper(local.server_name_array[1])
  group_project          = upper(local.server_name_array[3])
  group_replica_id       = upper(replace(local.server_name_array[2], "[^[:digit:]]", ""))
  rbac_platform          = var.platform == "nlv" ? "nle" : var.platform == "lv" ? "lve" : var.platform


  group_list = {
    for grp in var.entra_db_groups : "${var.server_name}-${lower(grp)}" => {
      groups = [
        "GRP_PGFS_CP_${local.group_environment_name}_${local.group_project}_${local.group_replica_id}_${grp}",
        "GRP_PGFS_CP_${local.group_project}_${grp}",
        "GRP_PGFS_CP_${upper(local.rbac_platform)}_${grp}",
        "GRP_PGFS_CP_${local.group_environment_name}_${grp}"
      ]
      group_name = lower(grp)
    }
  }
}




// Groups that grant a specific permission to this specific PGFS instance
resource "azuread_group" "instance_groups" {
  // Group creation may break if server name does not meed expected format (e.g. replica DBs).
  // In such a case, no groups will be created..
  for_each         = var.create_mode != "PointInTimeRestore" && length(var.entra_db_groups) > 0 ? var.entra_db_groups : []
  display_name     = "GRP_PGFS_CP_${local.group_environment_name}_${local.group_project}_${local.group_replica_id}_${each.key}"
  security_enabled = true
}
