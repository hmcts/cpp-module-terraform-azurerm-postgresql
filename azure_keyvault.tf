
// data "azurerm_client_config" "current" {}

data "azurerm_key_vault" "keyvault" {
  count               = var.enable_azure_keyvault ? 1 : 0
  name                = var.keyvault_name
  resource_group_name = var.keyvault_resource_group_name
}

resource "azurerm_key_vault_secret" "postgresql" {
  count        = var.enable_azure_keyvault ? 1 : 0
  name         = var.administrator_creds_azkv_secret_name
  value        = data.vault_generic_secret.administrator_creds.data["administrator_password"]
  key_vault_id = data.azurerm_key_vault.keyvault[0].id
}

data "azurerm_key_vault_secret" "entra_admin" {
  count        = var.enable_azure_keyvault ? 1 : 0
  key_vault_id = data.azurerm_key_vault.keyvault[0].id
  name         = var.entra_admin_pwd
}
