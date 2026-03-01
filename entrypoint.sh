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

# Configure SQL Server memory limits if not set
# With 32GB RAM, we allocate 24GB to SQL Server (leaving 8GB for OS)
if [ -z "$MSSQL_MEMORY_LIMIT_MB" ]; then
    # Default to 24GB (24576MB) for systems with 32GB RAM
    # Adjust this value based on your available RAM:
    # - 32GB total: 24576MB (24GB) recommended
    # - 16GB total: 12288MB (12GB) recommended
    # - 8GB total: 6144MB (6GB) recommended
    # - 4GB total: 2048MB (2GB) recommended
    export MSSQL_MEMORY_LIMIT_MB=24576
fi

echo "SQL Server memory limit configured: ${MSSQL_MEMORY_LIMIT_MB}MB ($(($MSSQL_MEMORY_LIMIT_MB / 1024))GB)"

# Set additional SQL Server configuration for stability
# Disable some features that can cause issues in containerized environments
export MSSQL_AGENT_ENABLED=false

# CRITICAL: Add trace flags to handle misaligned IOs and prevent stack overflow
# Trace flags are passed as arguments to sqlservr
# -T1800: Enable instant file initialization (reduces I/O operations)
# -T3226: Suppress successful backup messages (reduces log I/O)
# -T1117: Grow all files in a filegroup (prevents fragmentation)
# -T1118: Use uniform extents instead of mixed (reduces I/O overhead)
# -T2371: Auto-update statistics threshold (reduces blocking)
# -T3608: Skip recovery of secondary filegroups (faster startup, reduces I/O)
TRACE_FLAGS="-T1800 -T3226 -T1117 -T1118 -T2371 -T3608"

echo "SQL Server startup with trace flags: ${TRACE_FLAGS}"

# Start initialization script in background (will configure memory after SQL Server starts)
/init-sql.sh &

# Start SQL Server with trace flags to handle misaligned IOs
# In SQL Server Linux, trace flags are passed as command-line arguments
# The base image will handle switching to the mssql user
exec /opt/mssql/bin/sqlservr $TRACE_FLAGS
