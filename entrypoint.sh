#!/bin/bash
set -e

# Map SA_PASSWORD to MSSQL_SA_PASSWORD if SA_PASSWORD is set but MSSQL_SA_PASSWORD is not
if [ -n "$SA_PASSWORD" ] && [ -z "$MSSQL_SA_PASSWORD" ]; then
    export MSSQL_SA_PASSWORD="$SA_PASSWORD"
fi

# Ensure ACCEPT_EULA is set
export ACCEPT_EULA=Y

# Fix permissions for mounted volume (must run as root)
# SQL Server runs as user 'mssql' (UID 10001, GID 0)
if [ -d "/var/opt/mssql" ]; then
    # Ensure the directory structure exists
    mkdir -p /var/opt/mssql/data /var/opt/mssql/log /var/opt/mssql/secrets /var/opt/mssql/.system 2>/dev/null || true
    
    # Change ownership to mssql user (UID 10001, GID 0)
    # This is critical for Railway volumes
    chown -R 10001:0 /var/opt/mssql 2>/dev/null || true
    
    # Set permissions (read/write/execute for owner and group)
    chmod -R 775 /var/opt/mssql 2>/dev/null || true
    
    # Ensure .system directory has correct permissions
    if [ -d "/var/opt/mssql/.system" ]; then
        chown 10001:0 /var/opt/mssql/.system
        chmod 775 /var/opt/mssql/.system
    fi
fi

# Create .system symlink in root if it doesn't exist
# SQL Server tries to create /.system, so we create it as a symlink to /var/opt/mssql/.system
if [ ! -e "/.system" ] && [ -d "/var/opt/mssql/.system" ]; then
    ln -sf /var/opt/mssql/.system /.system 2>/dev/null || true
    # If symlink fails, try creating the directory in root with proper permissions
    if [ ! -e "/.system" ]; then
        mkdir -p /.system 2>/dev/null || true
        chown 10001:0 /.system 2>/dev/null || true
        chmod 775 /.system 2>/dev/null || true
    fi
fi

# Start SQL Server
# The base image will handle switching to the mssql user
exec /opt/mssql/bin/sqlservr
