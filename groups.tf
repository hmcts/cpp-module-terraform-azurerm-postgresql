#locals {
#  // Assumes var.server_name has the form "psf-{env}-ccm{id}-{project}"
#  // e.g. psf-prd-ccm01-progression
#  // May break for replicas
#  server_name_array      = split("-", var.server_name)
#  group_environment_name = upper(local.server_name_array[1])
#  group_project          = upper(local.server_name_array[3])
#  group_replica_id       = upper(trimprefix(local.server_name_array[2], "ccm"))
#}
#
#// Groups that grant a specific permission to this specific PGFS instance
locals {
  // Create a list of maps for each server and group, then flatten it
  flattened_instance_groups = flatten([
    for key, group_list in var.psql_instance_groups : [
      for group in group_list : {
        server_name = key
        group_name  = group
      }
    ]
  ])
}

resource "azuread_group" "instance_groups" {
  // Group creation may break if server name does not meed expected format (e.g. replica DBs).
  // In such a case, no groups will be created.
  for_each = {
    for idx, group in local.flattened_instance_groups : "${group.server_name}-${group.group_name}" => group
  }
  display_name = each.value.group_name
  mail_enabled = false
}
