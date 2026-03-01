# Use the official Microsoft SQL Server 2022 image
FROM mcr.microsoft.com/mssql/server:2022-latest

# Set environment variables for SQL Server
ENV ACCEPT_EULA=Y
ENV MSSQL_PID=Developer

# Copy entrypoint script with execute permissions
COPY --chmod=+x entrypoint.sh /entrypoint.sh

# Expose the default SQL Server port
EXPOSE 1433

# Use custom entrypoint (runs as root to fix permissions, then SQL Server switches to mssql user)
# Note: Volumes are configured in Railway dashboard, not in Dockerfile
ENTRYPOINT ["/entrypoint.sh"]
