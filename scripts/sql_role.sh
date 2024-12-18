#!/bin/bash
set -e
# Set PostgreSQL connection details

az login --service-principal -u ${client_id} -t ${tenant_id} -p ${entra_admin}
export PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query "[accessToken]" -o tsv)

echo '${jsonencode(${file_name})}' | jq -r 'to_entries[] | .value.group_name' | while read -r group_name; do
# Find all SQL files in the folder and execute them sequentially
for sql_file in $(ls ${path.module}/roles/final_${group_name}_${group_project}.sql | sort); do
    echo "Executing SQL file: $sql_file"
    psql -h ${server_fqdn} -p 5432 -U ${db_user} -d postgres -v 'ON_ERROR_STOP=1' -f ${sql_file}
done

