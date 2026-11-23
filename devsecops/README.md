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
