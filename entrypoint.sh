#!/bin/bash

# Map SA_PASSWORD to MSSQL_SA_PASSWORD if SA_PASSWORD is set but MSSQL_SA_PASSWORD is not
if [ -n "$SA_PASSWORD" ] && [ -z "$MSSQL_SA_PASSWORD" ]; then
    export MSSQL_SA_PASSWORD="$SA_PASSWORD"
fi

# Ensure ACCEPT_EULA is set
export ACCEPT_EULA=Y

# Start SQL Server
exec /opt/mssql/bin/sqlservr
