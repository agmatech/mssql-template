# Use the official Microsoft SQL Server 2022 image
FROM mcr.microsoft.com/mssql/server:2022-latest

# Set environment variables for SQL Server
ENV ACCEPT_EULA=Y
ENV MSSQL_PID=Developer

# SQL Server memory limit (default: 24GB for 32GB systems)
# Adjust MSSQL_MEMORY_LIMIT_MB via environment variable if needed
# Recommended: Leave 4-8GB for OS, assign rest to SQL Server
ENV MSSQL_MEMORY_LIMIT_MB=24576

# Copy entrypoint script with execute permissions
COPY --chmod=+x entrypoint.sh /entrypoint.sh
COPY --chmod=+x init-sql.sh /init-sql.sh

# Expose the default SQL Server port
EXPOSE 1433

# Ensure entrypoint runs as root to fix permissions
# Note: Volumes are configured in Railway dashboard, not in Dockerfile
USER root
ENTRYPOINT ["/entrypoint.sh"]
