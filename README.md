[![Build Status](https://dev.azure.com/azurerm-terraform-test/azurerm-terraform-modules/_apis/build/status/Azure.terraform-azurerm-postgresql)](https://dev.azure.com/azurerm-terraform-test/azurerm-terraform-modules/_build/latest?definitionId=2)
## Create an Azure PostgreSQL Database

This Terraform module creates a Azure PostgreSQL Database.

## Usage in Terraform 0.13

```hcl
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "example-rg"
  location = "West Europe"
}

module "postgresql" {
  source = "Azure/postgresql/azurerm"

  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  server_name                   = "example-server"
  sku_name                      = "GP_Gen5_2"
  storage_mb                    = 5120
  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  administrator_login           = "login"
  administrator_password        = "password"
  server_version                = "9.5"
  ssl_enforcement_enabled       = true
  public_network_access_enabled = true
  db_names                      = ["my_db1", "my_db2"]
  db_charset                    = "UTF8"
  db_collation                  = "English_United States.1252"

  firewall_rule_prefix = "firewall-"
  firewall_rules = [
    { name = "test1", start_ip = "10.0.0.5", end_ip = "10.0.0.8" },
    { start_ip = "127.0.0.0", end_ip = "127.0.1.0" },
  ]

  vnet_rule_name_prefix = "postgresql-vnet-rule-"
  vnet_rules = [
    { name = "subnet1", subnet_id = "<subnet_id>" }
  ]

  tags = {
    Environment = "Production",
    CostCenter  = "Contoso IT",
  }

  postgresql_configurations = {
    backslash_quote = "on",
  }

  depends_on = [azurerm_resource_group.example]
}
```

## Usage

```hcl
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "example-rg"
  location = "West Europe"
}

module "postgresql" {
  source = "Azure/postgresql/azurerm"

  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  server_name                   = "example-server"
  sku_name                      = "GP_Gen5_2"
  storage_mb                    = 5120
  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  administrator_login           = "login"
  administrator_password        = "password"
  server_version                = "9.5"
  ssl_enforcement_enabled       = true
  public_network_access_enabled = true
  db_names                      = ["my_db1", "my_db2"]
  db_charset                    = "UTF8"
  db_collation                  = "English_United States.1252"

  firewall_rule_prefix = "firewall-"
  firewall_rules = [
    { name = "test1", start_ip = "10.0.0.5", end_ip = "10.0.0.8" },
    { start_ip = "127.0.0.0", end_ip = "127.0.1.0" },
  ]

  vnet_rule_name_prefix = "postgresql-vnet-rule-"
  vnet_rules = [
    { name = "subnet1", subnet_id = "<subnet_id>" }
  ]

  tags = {
    Environment = "Production",
    CostCenter  = "Contoso IT",
  }

  postgresql_configurations = {
    backslash_quote = "on",
  }
}
```

## Immutable Backup Configuration

This module supports enrolling PostgreSQL Flexible Servers in Azure Data Protection Backup Vaults for immutable long-term backups based on service criticality ratings. This feature is controlled by a feature flag for gradual rollout.

### How It Works

The module uses a **criticality-based approach** where services are automatically enrolled in backup vaults based on their criticality rating:

- **Service Criticality Rating**: Scale from 1-5 (defaults to 1)
- **Enrollment Threshold**: Services with criticality **>= 4** are eligible for backup vault enrollment
- **Feature Flag**: `enable_immutable_backups` must be `true` to activate enrollment
- **Architecture**: The backup vault **pulls** backups from PostgreSQL (not a push model)
- **No Disruption**: Enrollment creates metadata only - no PostgreSQL restarts or configuration changes

### Requirements

1. Azure Data Protection Backup Vault must already exist
2. Backup policy must be created in the vault
3. Only supported for **PostgreSQL Flexible Server** (not single server)
4. Module automatically handles RBAC permissions for vault's managed identity

### Usage Example

```hcl
module "postgresql" {
  source = "Azure/postgresql/azurerm"

  # Standard configuration
  resource_group_name = "production-rg"
  location            = "uksouth"
  server_name         = "psf-prod-ccm01-myapp"
  sku_name            = "GP_Standard_D2s_v3"
  storage_mb          = 32768

  # Backup configuration for critical services
  service_criticality      = 5                           # Criticality rating 1-5
  enable_immutable_backups = true                        # Feature flag for controlled rollout
  backup_vault_name        = "backup-vault-prod"         # Existing backup vault name
  backup_vault_resource_group = "backup-infra-rg"        # Backup vault resource group
  backup_policy_name       = "postgresql-crit4-5"        # Policy name in the vault

  # ... other configuration
}
```

### Enrollment Decision Matrix

| service_criticality | enable_immutable_backups | single_server | Result |
|-------------------|------------------------|---------------|---------|
| 1, 2, or 3        | true                   | false         | ❌ No enrollment (criticality too low) |
| 4 or 5            | false                  | false         | ❌ No enrollment (feature flag disabled) |
| 4 or 5            | true                   | false         | ✅ **Enrolled in backup vault** |
| 4 or 5            | true                   | true          | ❌ No enrollment (single server not supported) |

### What Gets Created

When enrollment conditions are met, the module automatically:

1. **Data Source Lookup**: Queries the backup vault to get its managed identity
2. **RBAC Assignments**: Grants vault's identity two roles:
   - `Reader` on the resource group (read server metadata)
   - `PostgreSQL Flexible Server Long Term Retention Backup Role` on the server
3. **Backup Instance**: Enrolls the PostgreSQL server in the vault following the specified policy

### Important Notes

- **Default Criticality**: Defaults to `1` to prevent unintended backup vault enrollments
- **No Server Changes**: Enrollment is metadata only - no changes to PostgreSQL configuration or restarts
- **Pull Model**: Vault initiates backups on schedule; PostgreSQL server remains passive
- **RBAC Managed**: Module handles all necessary permissions automatically
- **Flexible Server Only**: Not supported for deprecated single server deployments
- **Backward Compatible**: Feature is opt-in; existing deployments remain unchanged

### Monitoring Enrollment

Check the module outputs to verify enrollment status:

```hcl
output "backup_status" {
  value = {
    enrolled            = module.postgresql.is_enrolled_in_backup_vault
    backup_instance_id  = module.postgresql.backup_instance_id
    backup_instance_name = module.postgresql.backup_instance_name
  }
}
```

### Reference Documentation

- [Azure Backup for PostgreSQL Flexible Server](https://learn.microsoft.com/en-gb/azure/backup/tutorial-create-first-backup-azure-database-postgresql-flex)
- [Data Protection Backup Instance Resource](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/data_protection_backup_instance_postgresql_flexible_server)

## Test

### Configurations

- [Configure Terraform for Azure](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-install-configure)

We provide 2 ways to build, run, and test the module on a local development machine.  [Native (Mac/Linux)](#native-maclinux) or [Docker](#docker).

### Native(Mac/Linux)

#### Prerequisites

- [Terraform **(~> 0.12.20)**](https://www.terraform.io/downloads.html)
- [Golang **(~> 1.10.3)**](https://golang.org/dl/)

#### Environment setup

We provide simple script to quickly set up module development environment:

```sh
$ curl -sSL https://raw.githubusercontent.com/Azure/terramodtest/master/tool/env_setup.sh | sudo bash
```

#### Run test

Then simply run it in local shell:

```sh
$ cd $GOPATH/src/{directory_name}/
$ ./test.sh full
```

### Docker

We provide a Dockerfile to build a new image based `FROM` the `microsoft/terraform-test` Docker hub image which adds additional tools / packages specific for this module (see Custom Image section).  Alternatively use only the `microsoft/terraform-test` Docker hub image [by using these instructions](https://github.com/Azure/terraform-test).

#### Prerequisites

- [Docker](https://www.docker.com/community-edition#/download)

#### Build the image

```sh
$ docker build --build-arg BUILD_ARM_SUBSCRIPTION_ID=$ARM_SUBSCRIPTION_ID --build-arg BUILD_ARM_CLIENT_ID=$ARM_CLIENT_ID --build-arg BUILD_ARM_CLIENT_SECRET=$ARM_CLIENT_SECRET --build-arg BUILD_ARM_TENANT_ID=$ARM_TENANT_ID -t azure-postgresql .
```

#### Run test (Docker)

This runs the local validation:

```sh
$ docker run --rm azure-postgresql /bin/bash -c "bundle install && rake build"
```

This runs the full tests (deploys resources into your Azure subscription):

```sh
$ docker run --rm azure-postgresql /bin/bash -c "bundle install && rake full"
```

## License

[MIT](LICENSE)

# Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
