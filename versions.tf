terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.103, < 4.0.0"
    }
  }
  required_version = ">= 0.12"
}
