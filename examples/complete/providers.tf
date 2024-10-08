terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.103"
    }

    vault = {
      source  = "hashicorp/vault"
      version = "=2.21.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "=3.1.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "=3.2.3"
    }
  }
}

provider "azurerm" {
  features {}
}
