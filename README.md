# Prácticas de automatización con Bash

Siete ejemplos para GNU/Linux con Bash. Leé cada script antes de ejecutarlo.
Todos usan `0` para éxito y un valor distinto de cero para fallo.
No necesitan ejecutarse todos con sudo.

## Ejemplos y ejecución

1. **Validar entorno antes de desplegar**
   ```bash
   REGISTRY=ghcr.io bash 01-validar-entorno.sh
   ```
   Requiere Docker en ejecución y curl. Comprueba herramientas, acceso al daemon
   y respuesta HTTP del registro. Un 401 indica autenticación requerida;
   no valida credenciales ni permisos para publicar.

2. **Verificar una API después del deploy**
   ```bash
   bash 02-comprobar-api.sh http://localhost:8000/metrics
   echo $?
   ```
   Hasta cinco intentos. Acepta únicamente HTTP 2xx. No sigue redirecciones
   ni valida el contenido de la respuesta. URL con query string: usar comillas.

3. **Respaldar PostgreSQL y ejecutar una migración**
   ```bash
   PGHOST=localhost PGPORT=5432 PGUSER=mi_usuario PGDATABASE=base_de_prueba \
     bash 03-backup-y-migracion.sh migracion.sql ./backups
   ```
   MODIFICA LA BASE: usar primero una base descartable. Requiere pg_dump,
   pg_restore y psql compatibles con el servidor. Usá ~/.pgpass para la contraseña
   con permisos 600. El SQL debe admitir ejecución en una única transacción y
   no gestionar sus propias transacciones. El script no genera ese SQL.
   Un backup lógico no equivale a respaldar todo el clúster: roles, por ejemplo,
   requieren otra estrategia. Listar el dump verifica su índice, NO sustituye
   probar una restauración. Si falla la migración, conserva el backup.

4. **Preparar desarrollo con Docker Compose**
   ```bash
   bash 04-preparar-desarrollo.sh /ruta/a/tu/proyecto
   ```
   CREA carpetas y, si hay .env.example, copia la configuración inicial y se
   detiene para que la completes. Requiere un proyecto Compose existente y una
   versión que admita --wait. CONSTRUYE e INICIA contenedores. Para verificar
   salud real, los servicios necesitan healthchecks; sin ellos se verifica arranque.
   No construye por vos un compose.yaml ni un Dockerfile.

5. **Recolectar diagnóstico**
   ```bash
   bash 05-recolectar-diagnostico.sh ./diagnosticos
   ```
   Genera una carpeta única con resultados y errores de cada consulta.
   Continúa si falla una consulta, pero termina con error si hubo fallos.
   El journal puede estar restringido y los logs pueden incluir datos sensibles:
   revisar antes de compartir. No exige acceso root.

6. **Consultar versiones por SSH**
   Creá servidores.txt con una entrada usuario@host por línea, sin espacios.
   Podés agregar comentarios con # al comienzo de una línea.
   ```bash
   bash 06-versiones-servidores.sh servidores.txt ~/.ssh/clave.pem ./versiones.tsv
   ```
   Requiere hosts ya verificados en known_hosts y autenticación por clave.
   Ejecuta únicamente uname -r en cada host. No modifica servidores.
   No sobrescribe reportes existentes. Registra errores y continúa con los demás.
   La clave no se copia al servidor ni al reporte.

7. **Detectar un umbral de disco**
   ```bash
   bash 07-comprobar-disco.sh / 80
   ```
   Consulta el sistema de archivos que contiene la ruta, no el tamaño de esa
   carpeta. Devuelve 1 si el uso es mayor o igual al umbral. Imprime una alerta;
   no manda emails ni borra archivos.

## Sintaxis que conviene estudiar

- `$(comando)`: capturar la salida de un comando.
- `${1:-valor}`: argumento opcional con valor predeterminado.
- `${1:?mensaje}`: argumento obligatorio.
- `if comando`: decidir según el código de salida.
- `"$variable"`: mantener un valor como un solo argumento.
- `> archivo` y `2> archivo`: guardar salida normal y errores por separado.
- `>&2`: escribir un mensaje en stderr.
- `set -euo pipefail`: detectar varios errores comunes. No reemplaza manejar
  explícitamente fallos esperables; `-e` tiene excepciones en condicionales.
- `umask 077`: crear archivos privados para el usuario actual.

## Uso desde Actions

```yaml
- name: Verificar API
  run: bash automatizaciones-bash/02-comprobar-api.sh https://mi-api.example/health
```

Para ejecutarlo periódicamente podés usar cron o timers de systemd.
Usá rutas absolutas y configurá el entorno: esos procesos no heredan
necesariamente lo mismo que tu terminal interactiva.

## Validación

Se comprobó sintaxis con bash -n en los siete scripts. Se probaron con un doble de curl los casos HTTP 200, HTTP 404 y conexión
rechazada. Se probaron consultas reales de disco y recolección de diagnóstico.
El sandbox no permite abrir un servidor HTTP local, por lo que la conectividad
HTTP real no se probó. Los scripts de Docker, SSH y PostgreSQL requieren
sus propios entornos de integración; no se realizaron despliegues ni migraciones.
