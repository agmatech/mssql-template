#!/bin/bash
set -e

# Ensure we're running as root for permission fixes
if [ "$(id -u)" != "0" ]; then
    echo "Warning: Not running as root. Some permission fixes may fail."
fi

# Map SA_PASSWORD to MSSQL_SA_PASSWORD if SA_PASSWORD is set but MSSQL_SA_PASSWORD is not
if [ -n "$SA_PASSWORD" ] && [ -z "$MSSQL_SA_PASSWORD" ]; then
    export MSSQL_SA_PASSWORD="$SA_PASSWORD"
fi

# Ensure ACCEPT_EULA is set
export ACCEPT_EULA=Y

# SQL Server runs as user 'mssql' (UID 10001, GID 0)
MSSQL_UID=10001
MSSQL_GID=0

# CRITICAL: Create /.system directory FIRST (SQL Server requires this in root)
# This must be done before SQL Server starts
if [ ! -d "/.system" ]; then
    mkdir -p /.system
    chown ${MSSQL_UID}:${MSSQL_GID} /.system
    chmod 775 /.system
    echo "Created /.system directory with permissions for mssql user"
fi

# Fix permissions for mounted volume
if [ -d "/var/opt/mssql" ]; then
    # Ensure the directory structure exists
    mkdir -p /var/opt/mssql/data /var/opt/mssql/log /var/opt/mssql/secrets /var/opt/mssql/.system
    
    # Change ownership to mssql user (UID 10001, GID 0)
    # This is critical for Railway volumes
    chown -R ${MSSQL_UID}:${MSSQL_GID} /var/opt/mssql
    
    # Set permissions (read/write/execute for owner and group)
    chmod -R 775 /var/opt/mssql
    
    # Ensure .system directory has correct permissions
    if [ -d "/var/opt/mssql/.system" ]; then
        chown ${MSSQL_UID}:${MSSQL_GID} /var/opt/mssql/.system
        chmod 775 /var/opt/mssql/.system
    fi
    
    echo "Fixed permissions for /var/opt/mssql volume"
fi

# Verify permissions
echo "Verifying permissions:"
ls -ld /.system 2>/dev/null || echo "Warning: /.system directory check failed"
ls -ld /var/opt/mssql 2>/dev/null || echo "Warning: /var/opt/mssql directory check failed"

# Start SQL Server
# The base image will handle switching to the mssql user
exec /opt/mssql/bin/sqlservr
