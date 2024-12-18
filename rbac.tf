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
    EOT
    environment = {
      render_template = templatefile("${path.module}/roles/${each.value.group_name}.sql", { groups = [for group in each.value.groups : lower(group)] })
    }
  }
}

resource "null_resource" "execute_sql_files" {
  for_each = local.group_list
  triggers = {
    server_fqdn      = azurerm_postgresql_flexible_server.flexible_server.0.fqdn
    client_id          = data.azuread_service_principal.current.client_id
    tenant_id           = data.azurerm_client_config.current.tenant_id
    entra_admin        = data.azurerm_key_vault_secret.entra_admin.0.value
    db_user          = var.entra_admin_user
    script_checksum  = filemd5("${path.module}/scripts/sql_role.sh")
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/sql_role.sh"
    environment = {
      server_fqdn = azurerm_postgresql_flexible_server.flexible_server.0.fqdn
      client_id     = data.azuread_service_principal.current.client_id
      tenant_id = data.azurerm_client_config.current.tenant_id
      entra_admin = data.azurerm_key_vault_secret.entra_admin.0.value
      db_user = var.entra_admin_user
      render_directory = "${path.module}/roles/"
      file_name = "final_${each.value.group_name}_${local.group_project}.sql"
    }
  }

  depends_on = [null_resource.render_sql_files]
}
