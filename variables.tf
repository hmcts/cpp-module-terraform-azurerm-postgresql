variable "resource_group_name" {
  description = "The name of the resource group in which to create the PostgreSQL Server. Changing this forces a new resource to be created."
  type        = string
}

variable "replica_resource_group_name" {
  description = "The name of the resource group in which to create the PostgreSQL Server. Changing this forces a new resource to be created."
  type        = string
}

variable "location" {
  description = "Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
  type        = string
}

variable "server_name" {
  description = "Specifies the name of the PostgreSQL Server. Changing this forces a new resource to be created."
  type        = string
}

variable "create_mode" {
  description = "The creation mode which can be used to restore or replicate existing servers"
  type        = string
  default     = null
}

variable "source_server_id" {
  description = "The resource ID of the source PostgreSQL Flexible Server to be restored"
  type        = string
  default     = null
}

variable "point_in_time_restore_time_in_utc" {
  description = "The point in time to restore from source_server_id"
  type        = string
  default     = null
}

variable "sku_name" {
  description = "Specifies the SKU Name for this PostgreSQL Server. The name of the SKU, follows the tier + family + cores pattern (e.g. B_Gen4_1, GP_Gen5_8)."
  type        = string
  default     = "GP_Gen5_4"
}

variable "storage_mb" {
  description = "Max storage allowed for a server. Possible values are between 5120 MB(5GB) and 1048576 MB(1TB) for the Basic SKU and between 5120 MB(5GB) and 4194304 MB(4TB) for General Purpose/Memory Optimized SKUs."
  type        = number
  default     = null
}

variable "storage_tier" {
  description = "Set disk Performance tier (possible values depend on storage_mb set)."
  type        = string
  default     = null
}

variable "auto_grow_enabled" {
  description = "Enable/Disable auto-growing of the storage."
  type        = bool
  default     = true
}

variable "flexible_auto_grow_enabled" {
  description = "Enable/Disable auto-growing of the storage."
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Backup retention days for the server, supported values are between 7 and 35 days."
  type        = number
  default     = 7
}

variable "geo_redundant_backup_enabled" {
  description = "Enable Geo-redundant or not for server backup. Valid values for this property are Enabled or Disabled, not supported for the basic tier."
  type        = bool
  default     = false
}

variable "administrator_login" {
  description = "The Administrator Login for the PostgreSQL Server. Changing this forces a new resource to be created."
  type        = string
  default     = "login"
}

variable "administrator_creds_vault_path" {
  description = "Vault path to store and retrive admin creds"
  type        = string
}




variable "server_version" {
  description = "Specifies the version of PostgreSQL to use. Valid values are 9.5, 9.6, and 10.0. Changing this forces a new resource to be created."
  type        = string
  default     = "9.5"
}

variable "ssl_enforcement_enabled" {
  description = "Specifies if SSL should be enforced on connections. Possible values are Enabled and Disabled."
  type        = bool
  default     = true
}

variable "ssl_minimal_tls_version_enforced" {
  description = "Specifies if SSL should be enforced on connections. Possible values are Enabled and Disabled."
  type        = string
  default     = "TLS1_2"
}

variable "public_network_access_enabled" {
  description = "Whether or not public network access is allowed for this server. Possible values are Enabled and Disabled."
  type        = bool
  default     = false
}

variable "single_server" {
  description = "Is the instance type single server or flexible server. Default is flexible server."
  type        = bool
  default     = false
}

variable "db_names" {
  description = "The list of names of the PostgreSQL Database, which needs to be a valid PostgreSQL identifier. Changing this forces a new resource to be created."
  type        = list(string)
  default     = []
}

variable "db_charset" {
  description = "Specifies the Charset for the PostgreSQL Database, which needs to be a valid PostgreSQL Charset. Changing this forces a new resource to be created."
  type        = string
  default     = "UTF8"
}

variable "db_collation" {
  description = "Specifies the Collation for the PostgreSQL Database, which needs to be a valid PostgreSQL Collation. Note that Microsoft uses different notation - en-US instead of en_US. Changing this forces a new resource to be created."
  type        = string
  default     = "English_United States.1252"
}

variable "delegated_subnet_id" {
  description = "Subnet ID where the flexible server need to be provisioned. Only apply to flexible server."
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Private zone ID for the DNS entry to be created. Only apply to flexible server."
  type        = string
  default     = null
}

variable "firewall_rule_prefix" {
  description = "Specifies prefix for firewall rule names."
  type        = string
  default     = "firewall-"
}

variable "firewall_rules" {
  description = "The list of maps, describing firewall rules. Valid map items: name, start_ip, end_ip."
  type        = list(map(string))
  default     = []
}

variable "vnet_rule_name_prefix" {
  description = "Specifies prefix for vnet rule names."
  type        = string
  default     = "postgresql-vnet-rule-"
}

variable "vnet_rules" {
  description = "The list of maps, describing vnet rules. Valud map items: name, subnet_id."
  type        = list(map(string))
  default     = []
}

variable "tags" {
  description = "A map of tags to set on every taggable resources. Empty by default."
  type        = map(string)
  default     = {}
}

variable "postgresql_configurations" {
  description = "A map with PostgreSQL configurations to enable."
  type        = map(string)
  default     = {}
}

variable "pgbouncer_configurations" {
  description = "A map with PgBouncer configurations to enable."
  type        = map(string)
  default     = {}
}

variable "extensions" {
  description = "This is value for azure extension under server configuration"
  type        = bool
  default     = false
}

variable "create_replica_instance" {
  description = "Create read replca for postgres instance. Accepted values true or false"
  type        = bool
  default     = false
}

variable "replica_instance_location" {
  description = "Geo location for read replica"
  type        = string
  default     = ""
}

variable "enable_monitoring" {
  description = "Enable monitoring for postgres instance. Accepted values true or false"
  type        = bool
  default     = false
}

variable "enable_azure_keyvault" {
  description = "Enable writing Hashicorp Secret to AZ KV Secret"
  type        = bool
  default     = false
}

variable "keyvault_name" {
  description = "Name of Azure Keyvault"
  type        = string
  default     = ""
}

variable "keyvault_resource_group_name" {
  description = "Name of Azure Keyvault RG"
  type        = string
  default     = ""
}

variable "administrator_creds_azkv_secret_name" {
  description = "Azure Vault to store/retrieve admin creds"
  type        = string
}


variable "log_analytics_workspace_enable_data_lookup" {
  description = "Disable for testing"
  type        = bool
  default     = true
}

variable "action_group_enable_data_lookup" {
  description = "Disable for testing"
  type        = bool
  default     = true
}

variable "action_group_name" {
  description = "Azure monitor Action Group"
  type        = string
  default     = "platformDevNotify"
}

variable "actiongroup_resource_group_name" {
  description = "Azure monitor action group resource group name"
  type        = string
  default     = "rg-mdv-int-01"
}

variable "log_analytics_workspace_name" {
  description = "Azure Log Analytics Workspace Name"
  type        = string
}

variable "log_analytics_workspace_resource_group_name" {
  description = "Azure Log Analytics Workspace Resource Group Name"
  type        = string
}

variable "log_to_azure_monitor_single_primary" {
  description = "Logging to Azure Monitor Settings for Primary Instance"
  type = object({
    enable = bool
    postgresql_logs = object({
      enabled = bool
    })
    querystore_runtime_statistics = object({
      enabled = bool
    })
    querystore_wait_statistics = object({
      enabled = bool
    })
    all_metrics = object({
      enabled = bool
    })
  })
  default = {
    enable = false
    postgresql_logs = {
      enabled = true
    }
    querystore_runtime_statistics = {
      enabled = true
    }
    querystore_wait_statistics = {
      enabled = true
    }
    all_metrics = {
      enabled = false
    }
  }
}

variable "log_to_azure_monitor_single_replica" {
  description = "Logging to Azure Monitor Settings for Replica Instance"
  type = object({
    enable = bool
    postgresql_logs = object({
      enabled = bool
    })
    querystore_runtime_statistics = object({
      enabled = bool
    })
    querystore_wait_statistics = object({
      enabled = bool
    })
    all_metrics = object({
      enabled = bool
    })
  })
  default = {
    enable = false
    postgresql_logs = {
      enabled = true
    }
    querystore_runtime_statistics = {
      enabled = true
    }
    querystore_wait_statistics = {
      enabled = true
    }
    all_metrics = {
      enabled = false
    }
  }
}

variable "log_to_azure_monitor_flexible" {
  description = "Logging to Azure Monitor Settings for Flexible Instance"
  type = object({
    enable = bool
    logs = object({
      PostgreSQLLogs = object({
        enabled = bool
      }),
      PostgreSQLFlexDatabaseXacts = object({
        enabled = bool
      }),
      PostgreSQLFlexQueryStoreRuntime = object({
        enabled = bool
      }),
      PostgreSQLFlexQueryStoreWaitStats = object({
        enabled = bool
      }),
      PostgreSQLFlexSessions = object({
        enabled = bool
      }),
      PostgreSQLFlexTableStats = object({
        enabled = bool
      }),
    })
    all_metrics = object({
      enabled = bool
    })
  })
  default = {
    enable = false
    logs = {
      PostgreSQLLogs = {
        enabled = false
      }
      PostgreSQLFlexDatabaseXacts = {
        enabled = false
      }
      PostgreSQLFlexQueryStoreRuntime = {
        enabled = false
      }
      PostgreSQLFlexQueryStoreWaitStats = {
        enabled = false
      }
      PostgreSQLFlexSessions = {
        enabled = false
      }
      PostgreSQLFlexTableStats = {
        enabled = false
      }
    }
    all_metrics = {
      enabled = false
    }
  }
}

variable "alerts_config_flexible" {
  description = "Configure alerts for flexible server"
  type = object({
    active_connections = object({
      aggregation       = string
      operator          = string
      alert_sensitivity = string
    }),
    connections_failed = object({
      aggregation       = string
      operator          = string
      alert_sensitivity = string
    }),
    cpu_percent = object({
      aggregation = string
      operator    = string
      threshold   = number
    }),
    memory_percent = object({
      aggregation = string
      operator    = string
      threshold   = number
    }),
    iops = object({
      aggregation       = string
      operator          = string
      alert_sensitivity = string
    })
    storage_percent = object({
      aggregation = string
      operator    = string
      threshold   = number
    })
  })
  default = {
    active_connections = {
      aggregation       = "Maximum"
      operator          = "GreaterThan"
      alert_sensitivity = "Low"
    }
    connections_failed = {
      aggregation       = "Total"
      operator          = "GreaterThan"
      alert_sensitivity = "Medium"
    }
    cpu_percent = {
      aggregation = "Average"
      operator    = "GreaterThan"
      threshold   = 95
    }
    memory_percent = {
      aggregation = "Average"
      operator    = "GreaterThan"
      threshold   = 95
    }
    iops = {
      aggregation       = "Maximum"
      operator          = "GreaterThan"
      alert_sensitivity = "Low"
    }
    storage_percent = {
      aggregation = "Average"
      operator    = "GreaterThan"
      threshold   = 90
    }
  }
}

variable "enable_bloat_monitoring" {
  description = "Enable bloat monitoring for postgres instance. Accepted values true or false"
  type = object({
    enable_bloat_monitoring = bool
    aggregation             = string
    operator                = string
    threshold               = number
    frequency               = string
    window_size             = string
    dbs_to_exclude          = list(string)
  })
  default = {
    enable_bloat_monitoring = false
    aggregation             = "Maximum"
    operator                = "GreaterThan"
    threshold               = 10
    frequency               = "PT1H"
    window_size             = "P1D"
    dbs_to_exclude          = ["azure_maintenance", "azure_sys", "postgres"]
  }
}

variable "action_group_id" {
  description = "action group id for alerts"
  type        = string
  default     = null
}

variable "create_lock" {
  description = "Set to true to create the lock, false to skip"
  type        = bool
  default     = true
}

variable "extensions_list" {
  description = "action group id for alerts"
  type        = string
  default     = "PG_BUFFERCACHE,PG_STAT_STATEMENTS"
}

variable "entra_admin_user" {
  description = "entra admin username"
  type        = string
}

variable "entra_admin_pwd" {
  description = "entra admin password"
  type        = string
}

variable "entra_db_groups" {
  description = "List of Entra groups to create for this DB"
  type        = set(string)
  default     = []

  validation {
    condition     = length(tolist(setsubtract(var.entra_db_groups, toset(["READ", "DBA", "EDITOR", "ADMIN"])))) == 0
    error_message = "Entra ID groups must be any of: ['READ', 'DBA', 'EDITOR', 'ADMIN']"
  }
}

variable "platform" {
  type    = string
  default = "nlv"
}
