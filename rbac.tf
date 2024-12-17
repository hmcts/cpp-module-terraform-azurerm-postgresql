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
      unique_sql_file_name="final_${each.value.group_name}_${local.group_project}.sql"
      echo "$render_template" > ${path.module}/roles/$unique_sql_file_name
      echo "SQL file created: ${path.module}/roles/$unique_sql_file_name"
      cat ${path.module}/roles/$unique_sql_file_name
    EOT
    environment = {
      render_template = templatefile("${path.module}/roles/${each.value.group_name}.sql", { groups = [for group in each.value.groups : lower(group)] })
    }
  }
}

resource "null_resource" "execute_sql_files" {


  provisioner "local-exec" {
    command = <<EOT
      # Log in to Azure using the service principal
      az login --service-principal -u ${data.azuread_service_principal.current.client_id} -t ${data.azurerm_client_config.current.tenant_id} -p ${data.azurerm_key_vault_secret.entra_admin.0.value}

      # Get the PostgreSQL access token from Azure
      export PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query "[accessToken]" -o tsv)

      # Loop through all .sql files in the roles directory and execute them one by one
      for sql_file in $(ls ${path.module}/roles/final_*.sql | sort); do
          echo "Executing SQL file: $sql_file"

          # Execute the SQL file using psql
         psql -h ${azurerm_postgresql_flexible_server.flexible_server.0.fqdn} -p 5432 -U ${var.entra_admin_user} -d postgres -v 'ON_ERROR_STOP=1' -f ${path.module}/roles/$sql_file

      done
    EOT
  }

  depends_on = [null_resource.render_sql_files]
}
