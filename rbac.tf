resource "null_resource" "render_sql_files" {
  for_each = local.group_list

  triggers = {
    content = templatefile("${path.module}/roles/${each.value.group_name}.sql", { groups = [for group in each.value.groups : lower(group)] })
  }

  depends_on = [
    azurerm_postgresql_flexible_server.flexible_server,
    azurerm_postgresql_flexible_server_active_directory_administrator.entra_admin,
    azuread_group.instance_groups
  ]

  provisioner "local-exec" {
    command = <<EOT
      # Define the merged file name for each instance (based on group_name or server_name)
      merged_sql_file_name="final_${each.value.group_name}_${local.group_project}.sql"
      merged_sql_file_path="${path.module}/roles/$merged_sql_file_name"

      # Clear the merged file if it exists or create a new one
      > $merged_sql_file_path

      # Loop through each group_name and append corresponding SQL file to the merged file
      group_sql_file="${path.module}/roles/${each.value.group_name}.sql"
      if [ -f "$group_sql_file" ]; then
        cat "$group_sql_file" >> $merged_sql_file_path
        echo "\n" >> $merged_sql_file_path  # Add a newline between files
      fi

      # List the files in the directory for debugging purposes
      ls -l ${path.module}/roles
    EOT

    environment = {
      render_template = templatefile("${path.module}/roles/${each.value.group_name}.sql", { groups = [for group in each.value.groups : lower(group)] })
    }
  }
}



#resource "null_resource" "execute_sql_files" {
#  triggers = {
#    group_names     = join(",", [for group in local.group_list : group.value.group_name])
#  }
#
#  provisioner "local-exec" {
#    command = <<EOT
#      # Sequentially execute SQL files for each group
#      for group_name in ${join(" ", [for group in local.group_list : group.value.group_name])}; do
#        # Construct the unique SQL file name for each group
#        unique_sql_file_name="final_${group_name}_${local.group_project}.sql"
#        #echo "Executing SQL file for ${group_name}..."
#        az login --service-principal -u ${data.azuread_service_principal.current.client_id} -t ${data.azurerm_client_config.current.tenant_id} -p ${data.azurerm_key_vault_secret.entra_admin.0.value}
#        export PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query "[accessToken]" -o tsv)
#        # Execute the SQL file using psql
#        psql -h ${azurerm_postgresql_flexible_server.flexible_server.0.fqdn} -p 5432 -U ${var.entra_admin_user} -d postgres -v 'ON_ERROR_STOP=1' -f ${path.module}/roles/$unique_sql_file_name
#      done
#    EOT
#  }
#
#  depends_on = [
#    azurerm_postgresql_flexible_server.flexible_server,
#    azurerm_postgresql_flexible_server_active_directory_administrator.entra_admin,
#    azuread_group.instance_groups,
#    null_resource.render_sql_files
#  ]
#}
