resource "null_resource" "db_setup" {
  for_each = var.rbac
  triggers = {
    content = templatefile("${path.module}/roles/${each.value.file}", { groups = each.value.groups })
  }
  depends_on = [azurerm_postgresql_flexible_server.flexible_server, azurerm_postgresql_flexible_server_active_directory_administrator.entra_admin]

  provisioner "file" {
    content     = templatefile("${path.module}/roles/${each.value.file}", { groups = each.value.groups })
    destination = "${path.module}/roles/final_${each.value.file}"
  }
  provisioner "local-exec" {
    command = <<EOT
      az login --service-principal -u 62dca24d-b574-4c40-bb88-fa8e192338fa -t e2995d11-9947-4e78-9de6-d44e0603518e
      export PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query "[accessToken]" -o tsv)
      psql -h ${azurerm_postgresql_flexible_server.flexible_server.0.name} -p 5432 -U ${var.entra_admin_user} -d postgres -f ${path.module}/roles/final_${each.value.file}
    EOT
    environment = {
      PGPASSWORD = "${data.azurerm_key_vault_secret.entra_admin.0.value}"
    }
  }
}
