# MSSQL 2022 Docker Image for Railway

Esta imagen Docker contiene Microsoft SQL Server 2022 y está configurada para ser deployada en Railway.

## Variables de Entorno Requeridas en Railway

Configura las siguientes variables de entorno en tu proyecto de Railway:

- `SA_PASSWORD` o `MSSQL_SA_PASSWORD`: Contraseña para el usuario SA (administrador). Debe cumplir con los requisitos de complejidad de SQL Server:
  - Al menos 8 caracteres
  - Contiene mayúsculas, minúsculas, números y caracteres especiales

**Nota**: El script de entrada mapea automáticamente `SA_PASSWORD` a `MSSQL_SA_PASSWORD` si es necesario.

## Deploy en Railway

1. Conecta tu repositorio a Railway
2. Railway detectará automáticamente el `Dockerfile`
3. Configura la variable de entorno `SA_PASSWORD` en el dashboard de Railway
4. Railway construirá y desplegará la imagen automáticamente

## Ejecutar Localmente

Para ejecutar la imagen localmente:

```bash
# Construir la imagen
docker build -t mssql-2022-railway .

# Ejecutar el contenedor
docker run -d --name mssql-2022-railway \
  -e "ACCEPT_EULA=Y" \
  -e "SA_PASSWORD=YourStrong@Passw0rd2024" \
  -p 1433:1433 \
  mssql-2022-railway

# Ver logs
docker logs -f mssql-2022-railway

# Detener el contenedor
docker stop mssql-2022-railway

# Eliminar el contenedor
docker rm mssql-2022-railway
```

## Conexión

- **Host**: El host proporcionado por Railway (o `localhost` para local)
- **Puerto**: 1433 (o el puerto asignado por Railway)
- **Usuario**: sa
- **Contraseña**: La que configuraste en `SA_PASSWORD`

### Ejemplo de cadena de conexión

```
Server=tu-host.railway.app,1433;Database=master;User Id=sa;Password=TuPassword;TrustServerCertificate=True;
```

## Notas

- La imagen usa la edición Developer de SQL Server (gratuita para desarrollo)
- El puerto 1433 está expuesto por defecto
- Railway asignará automáticamente el puerto externo
- El contenedor está configurado para reiniciarse automáticamente en caso de fallo
