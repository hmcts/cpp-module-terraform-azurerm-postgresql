resource "null_resource" "db_setup" {
  for_each = var.rbac
  triggers = {
    content = templatefile("${path.module}/roles/${each.value.file}", { groups = [for group in each.value.groups : lower(group)] })
  }
  depends_on = [azurerm_postgresql_flexible_server.flexible_server, azurerm_postgresql_flexible_server_active_directory_administrator.entra_admin]

  provisioner "local-exec" {
    command = <<EOT
      echo "$render_template" > ${path.module}/roles/final_${each.value.file}
      az login --service-principal -u ${data.azuread_service_principal.current.client_id} -t ${data.azurerm_client_config.current.tenant_id} -p ${data.azurerm_key_vault_secret.entra_admin.0.value}
      export PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query "[accessToken]" -o tsv)
      psql -h ${azurerm_postgresql_flexible_server.flexible_server.0.fqdn} -p 5432 -U ${var.entra_admin_user} -d postgres -v 'ON_ERROR_STOP=1' -f ${path.module}/roles/final_${each.value.file}
    EOT
    environment = {
      render_template = templatefile("${path.module}/roles/${each.value.file}", { groups = [for group in each.value.groups : lower(group)] })
    }
  }
}
