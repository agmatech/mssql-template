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

## Volúmenes y Persistencia de Datos

**Path del volumen en el contenedor**: `/var/opt/mssql`

Este es el directorio estándar donde MSSQL Server almacena:
- Todas las bases de datos (archivos `.mdf` y `.ldf`)
- Logs del sistema
- Archivos de configuración
- Backups

### Ejecutar Localmente con Volumen

**Opción 1: Usando Docker Compose (Recomendado)**

```bash
# Crear archivo .env con tu contraseña (opcional)
echo "SA_PASSWORD=YourStrong@Passw0rd2024" > .env

# Iniciar con docker-compose (crea volumen automáticamente)
docker-compose up -d

# Ver logs
docker-compose logs -f

# Detener
docker-compose down

# Detener y eliminar volumen (¡CUIDADO: elimina todos los datos!)
docker-compose down -v
```

**Opción 2: Usando Docker directamente**

```bash
# Construir la imagen
docker build -t mssql-2022-railway .

# Ejecutar con volumen nombrado
docker run -d --name mssql-2022-railway \
  -e "ACCEPT_EULA=Y" \
  -e "SA_PASSWORD=YourStrong@Passw0rd2024" \
  -p 1433:1433 \
  -v mssql_data:/var/opt/mssql \
  mssql-2022-railway

# O con un path local específico
docker run -d --name mssql-2022-railway \
  -e "ACCEPT_EULA=Y" \
  -e "SA_PASSWORD=YourStrong@Passw0rd2024" \
  -p 1433:1433 \
  -v $(pwd)/data:/var/opt/mssql \
  mssql-2022-railway

# Ver logs
docker logs -f mssql-2022-railway

# Detener el contenedor
docker stop mssql-2022-railway

# Eliminar el contenedor (el volumen persiste)
docker rm mssql-2022-railway
```

### Volúmenes en Railway

En Railway, los volúmenes persistentes se configuran desde el dashboard:
1. Ve a tu servicio en Railway
2. Abre la pestaña "Volumes"
3. Crea un nuevo volumen y mapea `/var/opt/mssql`
4. Railway manejará automáticamente la persistencia de datos

## Conexión

- **Host**: El host proporcionado por Railway (o `localhost` para local)
- **Puerto**: 1433 (o el puerto asignado por Railway)
- **Usuario**: sa
- **Contraseña**: La que configuraste en `SA_PASSWORD`

### Ejemplo de cadena de conexión

```
Server=tu-host.railway.app,1433;Database=master;User Id=sa;Password=TuPassword;TrustServerCertificate=True;
```

## Solución de Problemas

### Error: "The system directory [/.system] could not be created"

Si ves este error en Railway, el entrypoint ya está configurado para solucionarlo automáticamente:
- Crea el directorio `.system` en `/var/opt/mssql`
- Ajusta los permisos del volumen montado
- Crea un symlink o el directorio en la raíz si es necesario

Si el problema persiste:
1. Verifica que el volumen esté mapeado correctamente a `/var/opt/mssql` en Railway
2. Asegúrate de que la variable `SA_PASSWORD` esté configurada con una contraseña segura
3. Revisa los logs del contenedor en Railway para más detalles

## Notas

- La imagen usa la edición Developer de SQL Server (gratuita para desarrollo)
- El puerto 1433 está expuesto por defecto
- Railway asignará automáticamente el puerto externo
- El contenedor está configurado para reiniciarse automáticamente en caso de fallo
- **Importante**: Sin un volumen persistente, todos los datos se perderán al eliminar el contenedor
- El path del volumen debe ser siempre `/var/opt/mssql` dentro del contenedor
- El entrypoint ajusta automáticamente los permisos del volumen para el usuario `mssql` (UID 10001)
