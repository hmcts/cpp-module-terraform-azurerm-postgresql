environment = "test"

entra_admin_user = "azure-cli-2017-10-31-16-36-34"

tags = {
  domain      = "cpp.nonlive"
  platform    = "nlv"
  environment = "test"
  tier        = "data"
  project     = "paas"
}

tag_created_time  = ""
tag_created_by    = ""
tag_git_url       = ""
tag_git_branch    = ""
tag_last_apply    = ""
tag_last_apply_by = ""

# resource_group_name = "RG-LAB-CCM-01"

# replica_resource_group_name = "RG-LAB-CCM-02"

replica_instance_location = "ukwest"

subnet_config = {
  enable_data_lookup   = true
  subnet_name          = "SN-LAB-AZDAT-CCM-01"
  virtual_network_name = "VN-LAB-INT-01"
  resource_group_name  = "RG-LAB-INT-01"
}

private_dns_config = {
  enable_data_lookup  = false
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = "RG-MDV-INT-01"
}

vnet_rules = []

log_analytics_workspace_name = "LA-MDV-INT-WS"

log_analytics_workspace_resource_group_name = "RG-MDV-INT-01"

enable_monitoring = false

action_group_enable_data_lookup            = false
log_analytics_workspace_enable_data_lookup = false

psql_instances = [
  {
    server_name                  = "psf-lab-ccm01-hearing"
    sku_name                     = "B_Standard_B2s"
    storage_mb                   = 32768
    storage_tier                 = "P4"
    backup_retention_days        = 30
    geo_redundant_backup_enabled = null // Not required for flexible server
    server_version               = "11"
    create_replica_instance      = false
    single_server                = false
    firewall_rules               = []
    postgresql_configurations = {
      max_prepared_transactions           = "1000"
      log_duration                        = "OFF"
      log_error_verbosity                 = "TERSE"
      log_lock_waits                      = "on"
      log_min_duration_statement          = "250"
      backslash_quote                     = "on"
      idle_in_transaction_session_timeout = "60000"
      log_min_messages                    = "FATAL"
    }
    extensions = false
  },
]
