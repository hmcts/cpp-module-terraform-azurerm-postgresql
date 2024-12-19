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
      az login --service-principal -u ${data.azuread_service_principal.current.client_id} -t ${data.azurerm_client_config.current.tenant_id} -p ${data.azurerm_key_vault_secret.entra_admin.0.value}
      export PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query "[accessToken]" -o tsv)
      RETRY_COUNT=5
      RETRY_DELAY=10
      attempt=0
      while [ $attempt -lt $RETRY_COUNT ]; do
        psql -h ${azurerm_postgresql_flexible_server.flexible_server.0.fqdn} -p 5432 -U ${var.entra_admin_user} -d postgres -v 'ON_ERROR_STOP=1' -f ${path.module}/roles/$unique_sql_file_name
        if [ $? -eq 0 ]; then
          echo "SQL execution succeeded on attempt $attempt."
          break
        else
          attempt=$((attempt+1))
          echo "Attempt $attempt failed. Retrying in $RETRY_DELAY seconds..."
          sleep $RETRY_DELAY
        fi
      done
      if [ $attempt -eq $RETRY_COUNT ]; then
        echo "Failed after $RETRY_COUNT attempts."
        exit 1
      fi

    EOT
    environment = {
      render_template = templatefile("${path.module}/roles/${each.value.group_name}.sql", { groups = [for group in each.value.groups : lower(group)] })
    }
    on_failure = fail
  }
}


#resource "null_resource" "execute_sql_files" {
#  triggers = {
#    content = jsonencode({
#      for group in local.group_list : group.group_name => templatefile("${path.module}/roles/${group.group_name}.sql", { groups = [for g in group.groups : lower(g)] })
#    })
#  }
#
#  provisioner "local-exec" {
#    command = "bash -x ${path.module}/scripts/sql_role.sh"
#    environment = {
#      server_fqdn   = azurerm_postgresql_flexible_server.flexible_server.0.fqdn
#      client_id     = data.azuread_service_principal.current.client_id
#      tenant_id     = data.azurerm_client_config.current.tenant_id
#      entra_admin   = data.azurerm_key_vault_secret.entra_admin.0.value
#      db_user       = var.entra_admin_user
#      file_path     = "${path.module}/roles"
#      groups        = join(",", [for item in local.group_list : item.group_name])
#      group_project = local.group_project
#    }
#    on_failure = fail
#  }
#
#  depends_on = [
#    azurerm_postgresql_flexible_server.flexible_server,
#    azurerm_postgresql_flexible_server_active_directory_administrator.entra_admin,
#    azuread_group.instance_groups,
#    null_resource.render_sql_files
#  ]
#}
