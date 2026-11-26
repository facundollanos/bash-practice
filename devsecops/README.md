# Cinco automatizaciones DevSecOps

## Qué significa buscar vulnerabilidades

Es buscar debilidades que podrían afectar confidencialidad, integridad o
 disponibilidad: datos accesibles por otro usuario, ejecución de comandos,
 dependencias vulnerables o credenciales expuestas, por ejemplo.
Un hallazgo automático es evidencia para investigar, no una demostración de
explotabilidad. Tampoco un resultado sin hallazgos demuestra que todo sea seguro.

Ciclo de trabajo:
1. Definir activo, alcance y entorno de prueba.
2. Ejecutar el control apropiado.
3. Leer evidencia: archivo, línea, paquete, versión, endpoint o regla.
4. Confirmar si aplica, evaluar exposición y priorizar impacto.
5. Corregir la causa y volver a ejecutar el control.
6. Agregar una prueba que evite regresiones cuando corresponda.

## ¿Empiezo por OWASP Top 10?

Sí, es una buena guía de riesgos para aprender; no es un escáner ni una lista
exhaustiva de pruebas. La edición consultada es OWASP Top 10:2025:
https://top10.owasp.org/

Para tu primer recorrido: control de acceso, configuración, cadena de suministro,
inyección y autenticación. Ejemplo de control de acceso: un usuario no debería
poder leer una tarea de otro cambiando su ID en la URL. Eso requiere pruebas
con dos usuarios; estos cinco scripts no lo verifican automáticamente.

Para requisitos verificables y técnicas de prueba, después consultá ASVS y WSTG:
https://owasp.org/www-project-application-security-verification-standard/
https://owasp.org/www-project-web-security-testing-guide/

## Preparación

Los scripts NO instalan herramientas ni cambian el código del proyecto.
Requieren Bash sobre Linux. Las herramientas de análisis pueden consultar
servicios externos y descargar bases de vulnerabilidades.

Para los dos escáneres Python, podés preparar un entorno dedicado:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install bandit pip-audit
```

Instalación de las otras herramientas desde sus fuentes oficiales:
- Gitleaks: https://github.com/gitleaks/gitleaks#installing
- Trivy: https://trivy.dev/
- Docker para ZAP: https://docs.docker.com/engine/install/

Revisá y fijá versiones antes de usarlas en CI. ZAP usa la etiqueta móvil stable
para esta práctica; ZAP_IMAGE permite sustituirla por una imagen fijada por digest.
No se instalaron herramientas ni se descargaron imágenes al crear estos ejemplos.

## 1. SAST Python: Bandit

```bash
bash 01-sast-python.sh /ruta/mi-api/app
```

Busca patrones potencialmente inseguros en código Python sin arrancar la API.
Puede señalar subprocess con shell=True, mecanismos criptográficos inseguros,
etc. No equivale al análisis de flujo de todas las herramientas SAST ni detecta
todos los fallos de autorización o de lógica de negocio.

Reporte: bandit.json. Resultado 0: sin hallazgos según configuración; 1:
hallazgos, aunque otros errores también pueden producir fallo. Revisar salida
y reporte, no interpretar todo código no cero como una vulnerabilidad confirmada.

Documentación: https://bandit.readthedocs.io/en/latest/

## 2. SCA Python: pip-audit

```bash
bash 02-auditar-dependencias.sh /ruta/mi-api/requirements.txt
```

Cruza dependencias con avisos de vulnerabilidades conocidas. Trabajá con un
requirements confiable y versiones resueltas/fijadas para reproducibilidad.
Resolver dependencias puede requerir procesar metadatos o construir paquetes;
no ejecutar sobre proyectos desconocidos fuera de un entorno aislado.
No actualiza paquetes automáticamente. Una dependencia vulnerable requiere
revisar versión afectada, uso real y actualización disponible.

Reporte: pip-audit.json. 0: sin vulnerabilidades conocidas encontradas; 1:
hallazgos o error, a distinguir por el reporte y los mensajes.
Documentación: https://github.com/pypa/pip-audit

## 3. Secret scanning: Gitleaks

```bash
bash 03-detectar-secretos.sh /ruta/raiz-del-repositorio
```

Busca patrones de secretos en el historial Git disponible. No incluye archivos
sin commit ni historial que no se haya descargado: en Actions, checkout con
fetch-depth: 0 para disponer del historial accesible de la clonación.
Si detectás una credencial real expuesta, revocala o rotala; borrar la línea no
invalida la credencial ni elimina las copias del historial.

Reporte: gitleaks.json, con secretos redactados. 10: hallazgos; otros códigos
pueden indicar errores de ejecución. Requiere una versión con subcomando git.
Documentación: https://github.com/gitleaks/gitleaks

## 4. Imagen: Trivy

```bash
bash 04-auditar-imagen.sh mi-api:prueba
```

Analiza vulnerabilidades conocidas de paquetes de la imagen, filtradas a HIGH
 y CRITICAL. No comprueba tu API funcionando ni cubre todas las configuraciones.
Puede descargar la imagen y la base de vulnerabilidades. Para aprender podés
construir una imagen de tu propio proyecto antes del análisis.

Reporte: trivy.json. 10: hallazgos bajo esta política; otros códigos no cero:
error de herramienta. Para corregir: revisar paquete, actualizar imagen base o
 dependencia, reconstruir y volver a analizar. No modificar un contenedor a mano.
Documentación: https://trivy.dev/docs/latest/

## 5. Web en ejecución: ZAP Baseline

```bash
bash 05-web-zap-baseline.sh http://localhost:8000
```

Usar una aplicación propia o autorizada, preferentemente en un entorno de prueba.
Baseline explora enlaces y evalúa respuestas mediante reglas pasivas; no ejecuta
el escáner activo. Puede detectar headers o cookies problemáticos, por ejemplo.
Aun siendo pasivo el análisis, la exploración genera peticiones reales.
Una ruta /metrics sola aporta poca superficie: es mejor una web de práctica.
No configura autenticación ni garantiza cobertura de rutas, SPAs o APIs.

Requiere Docker Engine en Linux: --network host comparte la red del host.
Guarda reporte.html y reporte.json. La carpeta se monta con permisos del usuario
actual; si la imagen elegida requiere ajustes de permisos, revisar sus logs.

Códigos propios de ZAP: 0 sin WARN/FAIL; 1 al menos un FAIL; 2 WARN sin FAIL;
3 error de ejecución. Por defecto las alertas se clasifican como WARN.
El script conserva esos códigos: un 2 también hace fallar un paso de Actions.
No usamos || true ni -I para esconder alertas.

Documentación: https://www.zaproxy.org/docs/docker/baseline-scan/

## Reportes y Actions

Cada ejecución crea una carpeta privada nueva en reportes/, ignorada por Git.
REPORT_DIR permite elegir otra ubicación. Conserva codigo-salida.txt cuando la
herramienta termina; errores previos de validación no generan necesariamente reporte.
No publicar reportes automáticamente: pueden contener rutas, código o datos de la web.

```yaml
- name: SAST Python
  run: bash automatizaciones-bash/devsecops/01-sast-python.sh app
```

Ese paso presupone que Bandit ya fue instalado en el runner. Lo mismo aplica a
cada herramienta: el script es reutilizable, no instala su entorno.
La política de bloqueo es una decisión del equipo; documentar excepciones con
motivo y vencimiento, no ocultar todos los errores para que pase el pipeline.

## Orden de práctica

Primero Bandit sobre código tuyo; después pip-audit, Gitleaks, Trivy y ZAP.
Elegí un hallazgo y escribí: qué encontró, cómo lo confirmaste, qué impacto tiene,
qué corregiste y cómo verificaste la corrección. Eso vale más que acumular alertas.

## Validación realizada

Sintaxis bash -n y pruebas de argumentos, propagación de códigos y creación de
reportes con dobles locales de herramientas. No se ejecutaron escáneres reales,
no se instaló software y no se enviaron peticiones a aplicaciones.

## Nuevos ejemplos: 06 a 08

### 06. Checkov: infraestructura como código

```bash
bash 06-checkov-iac.sh /ruta/infra terraform
bash 06-checkov-iac.sh /ruta/manifiestos kubernetes
```

También admite dockerfile y github_actions. Requiere Checkov instalado; por
 ejemplo, en un entorno virtual dedicado: python -m pip install checkov.
No aplica infraestructura ni descarga módulos externos de Terraform; por ello
la cobertura de esos módulos puede quedar incompleta. Guarda checkov.json y el
código de salida original. 0 indica que pasó según la configuración efectiva;
un fallo puede ser incumplimiento de políticas o error de ejecución: leer el
reporte y stderr. No equivale a una certificación de seguridad. Checkov puede
leer configuración propia del proyecto; revisala para conocer exclusiones.
Documentación: https://www.checkov.io/2.Basics/CLI%20Command%20Reference.html

### 07. Permisos de archivos

```bash
bash 07-auditar-permisos.sh /ruta/proyecto
```

Busca archivos y carpetas con escritura para otros y archivos SUID/SGID. No cambia
permisos, sigue enlaces ni cruza sistemas de archivos. Guarda listas delimitadas
por NUL y una versión de texto con rutas escapadas. Una coincidencia no implica
una vulnerabilidad: /tmp, por ejemplo, suele permitir escritura y usar sticky bit.
Revisar propietario, sticky bit, necesidad real y contexto. No inspecciona ACL,
capabilities ni permisos de todos los directorios ascendientes.
Códigos: 0 sin coincidencias, 1 coincidencias, 2 inspección incompleta.
Requiere GNU find y realpath. No necesitás sudo salvo que el alcance lo requiera.

### 08. Vencimiento de certificado local

```bash
bash 08-comprobar-certificado.sh /ruta/certificado.pem 30
```

Requiere OpenSSL. Lee el primer certificado X.509 del archivo PEM y avisa si ya
venció o vencerá dentro de 30 días. No introducir una clave privada. No realiza
conexiones, no renueva certificados y no evalúa cadena de confianza, hostname,
revocación ni fecha de inicio de validez. Sirve como control de vencimiento,
no como auditoría TLS completa. Guarda metadatos del certificado en un reporte.
Códigos: 0 fuera del umbral, 1 alerta, 2 error de lectura, 64 argumentos inválidos.
Documentación: https://docs.openssl.org/3.0/man1/openssl-x509/

### Verificación de esta tanda

Los seis scripts nuevos pasaron bash -n. Se probaron respaldo y extracción,
rechazo de destino dentro del origen, descarga con curl simulado (hash correcto,
incorrecto y fallo de red), bloqueo concurrente y propagación de errores,
permisos con archivos temporales y certificados generados localmente con OpenSSL.
Checkov se verificó con un doble de herramienta, no con un análisis real.
No se descargaron archivos de Internet ni se modificaron servicios.

## Nuevos ejemplos: 09 a 11

### 09. Analizar scripts con ShellCheck

```bash
bash 09-shellcheck.sh /ruta/scripts
```

Requiere shellcheck instalado (https://www.shellcheck.net/). Analiza archivos .sh
 y .bash sin ejecutarlos, excluyendo .git, .venv y node_modules. Puede encontrar
expansiones sin comillas, errores de shell y construcciones problemáticas.
No es una auditoría completa de seguridad. Las fuentes externas no se analizan
 automáticamente: pueden aparecer avisos sobre source, a revisar según contexto.
Guarda shellcheck.json y conserva el código de salida de la herramienta.
No reescribe archivos. Una carpeta sin scripts se considera entrada inválida.

### 10. Revisar nombres sensibles en Git

```bash
bash 10-archivos-sensibles-git.sh /ruta/raiz/repositorio
```

Consulta el índice de Git: detecta candidatos como .env, claves, certificados y
estado de Terraform, incluidos archivos preparados sin commit. Excluye ejemplos
.env.example/.sample/.template. Solo analiza patrones de NOMBRE, no contenido ni
historial. Un certificado PEM público puede estar versionado legítimamente;
un secreto en configuracion.py puede pasar inadvertido. Complementa Gitleaks,
no lo reemplaza. Informa rutas sin imprimir su contenido. No borra archivos ni
los saca de Git. Si hay credenciales reales expuestas, revocar o rotar.
Salida 0 sin candidatos y 1 con candidatos; otros fallos requieren revisar stderr.

### 11. Comprobar integridad de artefactos

Generá un manifiesto en un entorno confiable; ejemplo:

```bash
(cd /ruta/artefactos && sha256sum app.zip config.json > SHA256SUMS)
bash 11-verificar-manifiesto.sh /ruta/artefactos/SHA256SUMS /ruta/artefactos
```

Requiere sha256sum y realpath (GNU/Linux). Compara archivos con hashes esperados,
registra coincidencias y conserva el código original de sha256sum. Archivos
faltantes, hashes diferentes o formato inválido hacen fallar la comprobación.
No comprueba archivos que el manifiesto no enumera y sigue enlaces simbólicos.
El manifiesto debe ser confiable: puede referenciar rutas absolutas o con ..;
no usar manifiestos desconocidos. SHA256 demuestra coincidencia con el manifiesto,
no autenticidad del publicador. Si alguien altera ambos, necesitás otra raíz de
confianza, por ejemplo una firma verificada. No ejecuta ni cambia los artefactos.

### Validación de esta tanda

Sintaxis de los seis scripts y pruebas con repositorios Git temporales, logs de
texto y manifiestos SHA256 reales. Se verificaron códigos de éxito y error con
dobles locales de curl y ShellCheck. No se realizaron consultas HTTP reales ni
se instaló ShellCheck. No se cambiaron repositorios de trabajo del usuario.
