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

## Nuevos ejemplos: 08 a 10

### 08. Respaldar una carpeta

```bash
bash 08-respaldar-carpeta.sh ./mi-proyecto ./backups
```

Crea un tar.gz único, privado, y comprueba integridad gzip. El destino debe estar
fuera del origen. No elimina respaldos antiguos. Si tar falla elimina el archivo
incompleto. No sustituye una prueba de restauración ni un snapshot consistente
para datos que cambian mientras se copian. No usar para bases de datos activas.
Requiere realpath, mktemp, tar y gzip (GNU/Linux).

### 09. Descargar y comprobar integridad

```bash
bash 09-descargar-verificado.sh 'https://servidor/archivo.zip' ./archivo.zip SHA256_REAL
```

Reemplazá SHA256_REAL por los 64 caracteres publicados por una fuente confiable.
Permite únicamente HTTPS, también en redirecciones, verifica SHA256 y publica el
archivo solo si coincide. No ejecuta lo descargado ni sobrescribe el destino.
Requiere curl, sha256sum, mktemp y ln; el sistema de archivos debe admitir enlaces
duros. El hash comprueba coincidencia; si lo obtuviste del mismo sitio comprometido
que el archivo, no demuestra autenticidad. La carpeta destino debe existir.

### 10. Evitar ejecuciones simultáneas

```bash
mkdir -p "$HOME/.local/state/bash-practice"
bash 10-ejecutar-con-bloqueo.sh \
  "$HOME/.local/state/bash-practice/backup.lock" \
  bash 08-respaldar-carpeta.sh ./mi-proyecto ./backups
```

Útil para tareas cron: si otra ejecución tiene el bloqueo, devuelve 75. Si logra
adquirirlo devuelve el código del comando ejecutado. Usá una carpeta privada y el
mismo lock en todas las ejecuciones. No borrar el archivo lock mientras hay tareas
activas. El comando debe permanecer en primer plano hasta terminar; no lanzar un
servicio con &. Los procesos hijos pueden heredar el descriptor del bloqueo.
Requiere flock (util-linux); pensado para disco local, no almacenamiento de red.

## Nuevos ejemplos: 11 a 13

### 11. Reporte local de Git

```bash
bash 11-reporte-git.sh /ruta/repositorio /tmp/reportes-git
```

Guarda estado, estadísticas de cambios preparados y sin preparar, y los últimos
10 commits. Acepta repositorios sin primer commit. No modifica commits ni hace
fetch. La información refleja solamente el estado local. Los nombres de archivos
y mensajes de commit pueden ser sensibles: revisar antes de compartir.
Requiere Git y mktemp. El directorio de reporte es único por ejecución.

### 12. Resumen de log de texto

```bash
bash 12-resumir-log.sh ./app.log
```

Cuenta líneas y coincidencias de palabras ERROR/FATAL, WARN/WARNING e INFO sin
 distinguir mayúsculas. Una línea puede pertenecer a varias categorías. No deduce
el nivel real de un evento estructurado y no cuenta excepciones multilínea como
un único evento. Una frase como "no error" también coincide. Requiere awk.
Un log vacío es válido; un archivo ilegible produce fallo.

### 13. Consultar varias URLs

Creá urls.txt con una URL HTTP/HTTPS por línea; admite líneas vacías y comentarios
que empiezan con #. No admite espacios en URLs: codificarlos si corresponden.

```bash
bash 13-comprobar-urls.sh ./urls.txt
```

Realiza GET en serie, muestra código HTTP y tiempo total y descarta el body.
Acepta solo 2xx, no sigue redirecciones, limita cada consulta a 10 segundos y
continúa con las demás si una falla. Es una foto, no monitoreo continuo.
No valida el contenido de respuestas ni configura autenticación. No pongas
tokens o credenciales en URLs: se imprimen en el reporte.
Salida 0 si todas pasan, 1 si alguna falla, 64 si no hay URLs o los argumentos
son inválidos. Requiere curl. Ejemplo de integración: guardar stdout como TSV.

## Tanda inspirada en Cybersecurity Ops with bash: 14 a 16

Ejercicios originales basados en los temas del libro, no transcripciones.

### 14. Inventario de archivos

```bash
bash 14-inventariar-archivos.sh /ruta/carpeta > /tmp/inventario.tsv
```

Recolecta tamaño, fecha de modificación Unix, permisos y ruta escapada con printf
%q. No lee el contenido ni sigue enlaces; no cruza sistemas de archivos. Requiere
GNU find, stat y realpath. Guardá el reporte FUERA del origen para no incluir el
propio reporte mientras cambia. Un error de acceso o archivo que desaparezca
produce fallo; el inventario no es un snapshot atómico ni un backup.

### 15. Ranking de clientes en access.log

```bash
bash 15-ranking-access-log.sh /ruta/access.log 10
```

Cuenta el primer campo de líneas no vacías de un access.log Common/Combined y
ordena por frecuencia. No valida IPs ni formatos: revisar antes una muestra del
log. Detrás de un proxy puede aparecer su dirección, no la del visitante.
No deduce identidad, ataques ni un intervalo temporal: analiza el archivo entero.
Requiere awk y sort; admite entre 1 y 100 resultados.

### 16. Detectar cambios de puertos TCP locales

```bash
bash 16-comparar-puertos.sh crear /tmp/puertos-base.txt
bash 16-comparar-puertos.sh comparar /tmp/puertos-base.txt
```

Captura endpoints TCP en escucha con ss, omitiendo PID y contadores. No consulta
máquinas remotas ni verifica firewalls. Crear no sobrescribe una baseline previa;
comparar no la actualiza. diff devuelve 0 si coinciden, 1 si hay cambios y 2 si
falla. Que un puerto cambie requiere investigar: no prueba una intrusión.
Requiere ss (iproute2), awk, sort y diff. Las consultas reflejan el namespace de
red actual. La comparación debe hacerse en el mismo entorno.

## Tanda con variables descriptivas: 17 a 19

Los nombres explícitos son una buena práctica: cantidad_archivos, ruta_archivo_json,
codigo_respuesta_http y directorio_ejecucion muestran la intención sin abreviaturas.

### 17. Validar JSON

```bash
bash 17-validar-archivos-json.sh /ruta/configuraciones
```

Recorre archivos .json y los parsea con python3 -m json.tool. No los modifica.
0: todos parsean; 1: alguno falla; 64: no hay archivos o entrada inválida.
Es validación de sintaxis según el parser de Python, NO de JSON Schema ni de
campos obligatorios. Python puede aceptar NaN/Infinity y claves duplicadas;
no usar como validador estricto de interoperabilidad JSON. No sigue enlaces.

### 18. Medir tiempos HTTP

```bash
bash 18-medir-respuesta-http.sh http://localhost:8000/metrics 3
```

Muestras secuenciales, separadas por un segundo, cada una con un proceso curl
nuevo. No es una prueba de carga. Muestra código y tiempos en segundos; conexión,
primer byte y total son ACUMULADOS desde el inicio, no duraciones independientes.
No sigue redirecciones; solo 2xx se considera éxito. 1 si alguna muestra falla.
Los errores de red pueden dejar tiempos parciales. No valida body. Requiere curl.

### 19. Ejecutar scripts en paralelo

```bash
bash 19-ejecutar-scripts-paralelos.sh /tmp/reportes ./tarea-a.sh ./tarea-b.sh
```

Ejecuta scripts Bash confiables SIN argumentos, en lotes de hasta dos. Guarda
stdout, stderr, código de salida y correspondencia entre número y ruta.
Las tareas deben ser independientes y terminar en primer plano. No usar con dos
migraciones o escrituras incompatibles. Conserva el directorio actual del llamador;
no cambia al directorio de cada script. Una tarea fallida no evita las siguientes;
al final devuelve 1 si hubo fallos. Este ejemplo no implementa cancelación de
árboles de procesos, timeouts ni límites de recursos; no usar con tareas infinitas.
