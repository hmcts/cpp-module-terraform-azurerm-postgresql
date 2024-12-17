#!/bin/bash
set -e
# Set PostgreSQL connection details

az login --service-principal -u ${client_id} -t ${tenant_id} -p ${entra_admin}
export PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query "[accessToken]" -o tsv)


# Find all SQL files in the folder and execute them sequentially
for sql_file in $(ls ${render_directory}/final_*.sql | sort); do
    echo "Executing SQL file: $sql_file"
    psql -h ${server_fqdn} -p 5432 -U ${db_user} -d postgres -v 'ON_ERROR_STOP=1' -f ${render_directory}/${sql_file}
done

