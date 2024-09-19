data "azurerm_client_config" "current" {
}

data "azuread_service_principal" "current" {
  display_name = var.entra_admin_user
}
