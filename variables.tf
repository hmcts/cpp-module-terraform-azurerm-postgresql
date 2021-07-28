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

variable "sku_name" {
  description = "Specifies the SKU Name for this PostgreSQL Server. The name of the SKU, follows the tier + family + cores pattern (e.g. B_Gen4_1, GP_Gen5_8)."
  type        = string
  default     = "GP_Gen5_4"
}

variable "storage_mb" {
  description = "Max storage allowed for a server. Possible values are between 5120 MB(5GB) and 1048576 MB(1TB) for the Basic SKU and between 5120 MB(5GB) and 4194304 MB(4TB) for General Purpose/Memory Optimized SKUs."
  type        = number
  default     = 102400
}

variable "auto_grow_enabled" {
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

variable "private_endpoint_enabled" {
  description = "Whether or not private endpoint is enabled for this server. Possible values are true and false."
  type        = bool
  default     = false
}

variable "private_endpoint_name_prefix" {
  description = "Prefix for private endpoint name"
  type        = string
  default     = "pe"
}

variable "private_endpoint_subnet_id" {
  description = "The subnet ID where the private link need to be created."
  type        = string
  default     = ""
}

variable "private_endpoint_replica_subnet_id" {
  description = "The subnet ID where the private link need to be created. Replica instance"
  type        = string
  default     = ""
}

variable "private_service_connection_name_prefix" {
  description = "Private service connection name prefix"
  type        = string
  default     = "pc"
}

variable "private_service_connection_is_manual" {
  description = "Does the Private Endpoint require Manual Approval from the remote resource owner. Possible values are true and false."
  type        = bool
  default     = false
}

variable "privatelink_dns_zone_name" {
  description = "Name of the privatelink zone."
  type        = string
  default     = ""
}

variable "privatelink_dns_zone_group_name" {
  description = "Specifies the Name of the Private DNS Zone Group"
  type        = string
  default     = ""
}

variable "privatelink_dns_zone_id" {
  description = "Specifies the list of Private DNS Zones to include within the private_dns_zone_group"
  type        = string
  default     = ""
}

variable "privatelink_dns_zone_rg_name" {
  description = "Privatelink zone resource group name"
  type        = string
  default     = ""
}

# variable "dns_cname_ttl" {
#   description = "DNS CNAME record TTL"
#   type        = number
#   default     = 300
# }