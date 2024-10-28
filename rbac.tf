resource "null_resource" "db_setup" {
  for_each = local.group_list
  triggers = {
    content = templatefile("${path.module}/roles/${each.value.group_name}.sql", { groups = [for group in each.value.groups : lower(group)] })
  }
  depends_on = [azurerm_postgresql_flexible_server.flexible_server, azurerm_postgresql_flexible_server_active_directory_administrator.entra_admin, azuread_group.instance_groups]

  provisioner "local-exec" {
    command = <<EOT
      unique_sql_file_name="final_${each.value.group_name}_${local.group_project}.sql"
      echo "$render_template" > ${path.module}/roles/$unique_sql_file_name
      az login --service-principal -u ${data.azuread_service_principal.current.client_id} -t ${data.azurerm_client_config.current.tenant_id} -p ${data.azurerm_key_vault_secret.entra_admin.0.value}
      export PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query "[accessToken]" -o tsv)
      max_retries=5
      count=0
      success=0
      while [ $count -lt $max_retries ]; do
        # Execute the SQL file
        psql -h ${azurerm_postgresql_flexible_server.flexible_server.0.fqdn} -p 5432 -U ${var.entra_admin_user} -d postgres -v 'ON_ERROR_STOP=1' -f ${path.module}/roles/$unique_sql_file_name

        # Check if the previous command succeeded
        if [ $? -eq 0 ]; then
          success=1
          echo "SQL command executed successfully."
          break
        else
          echo "Error encountered during SQL execution. Retrying..."
          ((count++))
          sleep 2 # wait before retrying
        fi
      done

      if [ $success -eq 0 ]; then
        echo "Failed to execute SQL command after $max_retries attempts."
        exit 1
      fi
    EOT
    environment = {
      render_template = templatefile("${path.module}/roles/${each.value.group_name}.sql", { groups = [for group in each.value.groups : lower(group)] })
    }
  }
}
