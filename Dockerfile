# Use the official Microsoft SQL Server 2022 image
FROM mcr.microsoft.com/mssql/server:2022-latest

# Set environment variables for SQL Server
ENV ACCEPT_EULA=Y
ENV MSSQL_PID=Developer

# Limit SQL Server memory usage to prevent stack overflow
# Railway typically provides limited resources, so we limit SQL Server memory
ENV MSSQL_MEMORY_LIMIT_MB=2048

# Copy entrypoint script with execute permissions
COPY --chmod=+x entrypoint.sh /entrypoint.sh
COPY --chmod=+x init-sql.sh /init-sql.sh

# Expose the default SQL Server port
EXPOSE 1433

# Ensure entrypoint runs as root to fix permissions
# Note: Volumes are configured in Railway dashboard, not in Dockerfile
USER root
ENTRYPOINT ["/entrypoint.sh"]
