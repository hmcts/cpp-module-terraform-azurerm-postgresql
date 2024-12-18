#!/bin/bash
set -e
# Set PostgreSQL connection details

az login --service-principal -u ${client_id} -t ${tenant_id} -p ${entra_admin}
export PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query "[accessToken]" -o tsv)



IFS=',' read -r -a group_array <<< "$groups"
for group in "${group_array[@]}"; do
  sql_file="final_${group}_${group_project}.sql"

  # Check if the file exists and loop through it
  if [[ -f "${path_module}/roles/${sql_file}" ]]; then
    echo "Executing SQL file: ${sql_file}"
    psql -h "${server_fqdn}" -p 5432 -U "${db_user}" -d postgres -v 'ON_ERROR_STOP=1' -f "${path_module}/roles/${sql_file}"
  fi
done





