
locals {
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
  for_each = {
    for idx, group in local.flattened_instance_groups : "${group.server_name}-${group.group_name}" => group
  }
  display_name = each.value.group_name
  mail_enabled = false
}
