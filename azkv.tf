
// data "azurerm_client_config" "current" {}

data "azurerm_key_vault" "keyvault" {
  name                = var.keyvault_name
  resource_group_name = var.keyvault_resource_group_name
}

resource "azurerm_key_vault_secret" "postgresql" {
  name         = var.administrator_creds_azkv_secret_name
  value        = data.vault_generic_secret.administrator_creds.data["administrator_password"]
  key_vault_id = data.azurerm_key_vault.keyvault.id
}
