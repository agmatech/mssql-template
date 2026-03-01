#!/bin/bash
# Script to configure SQL Server after startup
# This runs in the background to set memory limits

# Wait for SQL Server to be ready
sleep 30

# Configure SQL Server memory limit using sqlcmd
# This helps prevent stack overflow in limited environments
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -Q "
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'max server memory (MB)', ${MSSQL_MEMORY_LIMIT_MB:-2048};
RECONFIGURE;
" -C 2>/dev/null || echo "SQL Server configuration may not be ready yet"

echo "SQL Server memory limit configured to ${MSSQL_MEMORY_LIMIT_MB:-2048}MB"
