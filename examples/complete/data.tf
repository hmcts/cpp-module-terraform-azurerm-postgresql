data "azurerm_subnet" "delegated_subnet_id" {
  count                = var.subnet_config.enable_data_lookup ? 1 : 0
  name                 = var.subnet_config.subnet_name
  virtual_network_name = var.subnet_config.virtual_network_name
  resource_group_name  = var.subnet_config.resource_group_name
}

data "azurerm_private_dns_zone" "private_dns_zone_id" {
  count               = var.private_dns_config.enable_data_lookup ? 1 : 0
  name                = var.private_dns_config.name
  resource_group_name = var.private_dns_config.resource_group_name
}

data "azurerm_virtual_network" "vnet" {
  name                = var.subnet_config.virtual_network_name
  resource_group_name = var.subnet_config.resource_group_name
}
