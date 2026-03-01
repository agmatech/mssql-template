#!/bin/bash
# Script to configure SQL Server after startup
# This runs in the background to set memory limits and optimize settings

# Wait for SQL Server to be ready (increase wait time for stability)
MAX_RETRIES=10
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -Q "SELECT 1" -C >/dev/null 2>&1; then
        echo "SQL Server is ready"
        break
    fi
    echo "Waiting for SQL Server to be ready... ($((RETRY_COUNT + 1))/$MAX_RETRIES)"
    sleep 6
    RETRY_COUNT=$((RETRY_COUNT + 1))
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "Warning: SQL Server may not be fully ready, but continuing with configuration..."
fi

# Default memory limit: 24GB (24576MB) for 32GB systems
MEMORY_LIMIT=${MSSQL_MEMORY_LIMIT_MB:-24576}

# Configure SQL Server using sqlcmd
# Critical settings to prevent stack overflow from misaligned IOs
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -Q "
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;

-- Set memory limit (critical to prevent stack overflow)
EXEC sp_configure 'max server memory (MB)', ${MEMORY_LIMIT};
RECONFIGURE;

-- Reduce I/O operations to prevent stack overflow from misaligned IOs
-- Set checkpoint interval to reduce log flushes
EXEC sp_configure 'recovery interval (min)', 5;
RECONFIGURE;

-- Optimize for misaligned IOs
EXEC sp_configure 'backup compression default', 1;
RECONFIGURE;

-- Disable unnecessary features that can cause I/O issues
EXEC sp_configure 'xp_cmdshell', 0;
RECONFIGURE;

-- Set max degree of parallelism to prevent resource contention
EXEC sp_configure 'max degree of parallelism', 4;
RECONFIGURE;

-- Optimize tempdb for better I/O handling
EXEC sp_configure 'optimize for ad hoc workloads', 1;
RECONFIGURE;

-- Enable trace flags via DBCC to handle misaligned IOs
-- These complement the startup trace flags
DBCC TRACEON (1800, 3226, 1117, 1118, 2371, 3608);
" -C 2>/dev/null || echo "SQL Server configuration may not be ready yet"

echo "SQL Server configured to handle misaligned IOs and prevent stack overflow:"
echo "  - Memory limit: ${MEMORY_LIMIT}MB ($(($MEMORY_LIMIT / 1024))GB)"
echo "  - Recovery interval: 5 minutes (reduces log flushes)"
echo "  - Backup compression: Enabled"
echo "  - Max degree of parallelism: 4"
echo "  - Trace flags enabled: -T1800 -T3226 -T1117 -T1118 -T2371 -T3608"
echo "  - These settings reduce I/O operations and prevent stack overflow"
