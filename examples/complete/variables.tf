variable "environment" {
  type        = string
  description = "Environment name"
}

variable "resource_group_name" {
  type        = string
  description = "AKS resource group name"
  default     = ""
}

variable "replica_resource_group_name" {
  type        = string
  description = "AKS resource group name"
  default     = ""
}

variable "tags" {
  type = map(any)
}

variable "tag_created_time" {
  type        = string
  description = "Timestamp when resource has been created"
}

variable "tag_created_by" {
  type        = string
  description = "User who run the job when resource was created"
}

variable "tag_git_url" {
  type        = string
  description = "GIT URL of the project"
}

variable "tag_git_branch" {
  type        = string
  description = "GIT Branch from where changes being applied"
}

variable "tag_last_apply" {
  type        = string
  description = "Current timestamp when changes applied"
}

variable "tag_last_apply_by" {
  type        = string
  description = "USER ID of the person who is applying the changes"
}

variable "location" {
  type        = string
  description = "Geo location where the resource to be deployed"
  default     = "uksouth"
}

variable "replica_instance_location" {
  type        = string
  description = "Geo location where the resource to be deployed"
  default     = "ukwest"
}

variable "enable_monitoring" {
  type        = bool
  description = "if set to true it will enable monitoring and configure alerts"
  default     = false
}

variable "subnet_config" {
  description = "VNET, Subnet and resourcegroup details"
  type = object({
    enable_data_lookup   = bool
    subnet_name          = string
    virtual_network_name = string
    resource_group_name  = string
  })
  default = {
    enable_data_lookup   = false
    subnet_name          = null
    virtual_network_name = null
    resource_group_name  = null
  }
}

variable "private_dns_config" {
  description = "Private DNS Zone details"
  type = object({
    enable_data_lookup  = bool
    name                = string
    resource_group_name = string
  })
  default = {
    enable_data_lookup  = false
    name                = null
    resource_group_name = null
  }
}

variable "vnet_rules" {
  type = list(object({
    source_vnet_name                = string
    source_vnet_resource_group_name = string
    source_subnets                  = list(string)
  }))
}

variable "psql_instances" {
  type = list(object({
    server_name                  = string
    sku_name                     = string
    single_server                = bool
    storage_mb                   = number
    backup_retention_days        = number
    geo_redundant_backup_enabled = bool
    server_version               = string
    postgresql_configurations    = map(string)
    create_replica_instance      = bool
    firewall_rules               = list(map(string))
    extensions                   = bool
  }))
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
  description = "Logging to Azure Monitor Settings for Primary Instance. Option only for single server."
  type = object({
    enable = bool
    postgresql_logs = object({
      enabled           = bool
      retention_enabled = bool
      retention_days    = number
    })
    querystore_runtime_statistics = object({
      enabled           = bool
      retention_enabled = bool
      retention_days    = number
    })
    querystore_wait_statistics = object({
      enabled           = bool
      retention_enabled = bool
      retention_days    = number
    })
    all_metrics = object({
      enabled           = bool
      retention_enabled = bool
      retention_days    = number
    })
  })
  default = {
    enable = false
    postgresql_logs = {
      enabled           = false
      retention_enabled = false
      retention_days    = 0
    }
    querystore_runtime_statistics = {
      enabled           = false
      retention_enabled = false
      retention_days    = 0
    }
    querystore_wait_statistics = {
      enabled           = false
      retention_enabled = false
      retention_days    = 0
    }
    all_metrics = {
      enabled           = false
      retention_enabled = false
      retention_days    = 0
    }
  }
}

variable "log_to_azure_monitor_single_replica" {
  description = "Logging to Azure Monitor Settings for Replica Instance. Option only for single server."
  type = object({
    enable = bool
    postgresql_logs = object({
      enabled           = bool
      retention_enabled = bool
      retention_days    = number
    })
    querystore_runtime_statistics = object({
      enabled           = bool
      retention_enabled = bool
      retention_days    = number
    })
    querystore_wait_statistics = object({
      enabled           = bool
      retention_enabled = bool
      retention_days    = number
    })
    all_metrics = object({
      enabled           = bool
      retention_enabled = bool
      retention_days    = number
    })
  })
  default = {
    enable = false
    postgresql_logs = {
      enabled           = false
      retention_enabled = false
      retention_days    = 0
    }
    querystore_runtime_statistics = {
      enabled           = false
      retention_enabled = false
      retention_days    = 0
    }
    querystore_wait_statistics = {
      enabled           = false
      retention_enabled = false
      retention_days    = 0
    }
    all_metrics = {
      enabled           = false
      retention_enabled = false
      retention_days    = 0
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
      threshold   = 90
    }
    memory_percent = {
      aggregation = "Average"
      operator    = "GreaterThan"
      threshold   = 90
    }
    iops = {
      aggregation       = "Maximum"
      operator          = "GreaterThan"
      alert_sensitivity = "Low"
    }
    storage_percent = {
      aggregation = "Average"
      operator    = "GreaterThan"
      threshold   = 80
    }
  }
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
