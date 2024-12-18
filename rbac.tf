resource "null_resource" "render_sql_files" {
  triggers = {
    content = join(",", [for group in local.group_list : templatefile("${path.module}/roles/${group.group_name}.sql", { groups = [for g in group.groups : lower(g)] })])
  }

  depends_on = [
    azurerm_postgresql_flexible_server.flexible_server,
    azurerm_postgresql_flexible_server_active_directory_administrator.entra_admin,
    azuread_group.instance_groups
  ]

  provisioner "local-exec" {
    command = <<EOT
      # Encode the group list as JSON and parse it with jq
      echo '${jsonencode(local.group_list)}' | jq -r 'to_entries[] | .value.group_name' | while read -r grp; do
        # Render the SQL file for each group
        unique_sql_file_name="final_$grp_${local.group_project}.sql"
        render_template=$(templatefile("${path.module}/roles/$grp.sql", { groups = [for g in local.group_list[grp].groups : lower(g)] }))
        echo "$render_template" > ${path.module}/roles/$unique_sql_file_name
        echo "Executing SQL file for group: $grp"

        # Assuming psql for PostgreSQL, replace with your relevant SQL client
        psql -h ${azurerm_postgresql_flexible_server.flexible_server.0.fqdn} -U ${var.entra_admin_user} -d postgres  -v 'ON_ERROR_STOP=1' -f ${path.module}/roles/$unique_sql_file_name

        echo "Finished executing SQL file for group: $grp"
      done
    EOT
  }
}


#resource "null_resource" "execute_sql_files" {
#  triggers = {
#    server_fqdn      = azurerm_postgresql_flexible_server.flexible_server.0.fqdn
#    client_id          = data.azuread_service_principal.current.client_id
#    tenant_id           = data.azurerm_client_config.current.tenant_id
#    entra_admin        = data.azurerm_key_vault_secret.entra_admin.0.value
#    db_user          = var.entra_admin_user
#    script_checksum  = filemd5("${path.module}/scripts/sql_role.sh")
#    sql_files_checksum = file("${path.module}/roles/sql_files_checksum.txt")
#  }
#
#  provisioner "local-exec" {
#    command = "bash -x ${path.module}/scripts/sql_role.sh"
#    environment = {
#      server_fqdn = azurerm_postgresql_flexible_server.flexible_server.0.fqdn
#      client_id     = data.azuread_service_principal.current.client_id
#      tenant_id = data.azurerm_client_config.current.tenant_id
#      entra_admin = data.azurerm_key_vault_secret.entra_admin.0.value
#      db_user = var.entra_admin_user
#      file_path = "${path.module}/roles"
#      groups = join(",", [for item in local.group_list : item.group_name])
#      group_project = local.group_project
#    }
#    on_failure = fail
#  }
#
#  depends_on = [null_resource.render_sql_files]
#}
