#!/bin/bash
set -e
# Set PostgreSQL connection details

az login --service-principal -u ${az_user} -t ${tenant} -p ${client_id}
export PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query "[accessToken]" -o tsv)


# Find all SQL files in the folder and execute them sequentially
for sql_file in $(ls ${render_template}/final_*.sql | sort); do
    echo "Executing SQL file: $sql_file"
    psql -h ${server_fqdn} -p 5432 -U ${DB_USER} -d postgres -v 'ON_ERROR_STOP=1' -f ${render_template}/${sql_file}
    if [[ $? -ne 0 ]]; then
        echo "Error executing $sql_file. Exiting."
        exit 1
    fi
    echo "Successfully executed: $sql_file"
done

echo "All SQL files executed successfully."
