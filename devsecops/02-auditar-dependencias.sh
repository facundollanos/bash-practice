#!/usr/bin/env bash
# Uso: bash 02-auditar-dependencias.sh /ruta/requirements.txt
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/comun.bash"
archivo="${1:?Uso: $0 /ruta/requirements.txt}"
[[ -f "$archivo" && -r "$archivo" ]] || { printf 'Requirements ilegible.\n' >&2; exit 64; }
requerir pip-audit
crear_reporte dependencias
# No usar --fix: este ejemplo informa, no actualiza tus dependencias.
# La resolución puede procesar paquetes: usar únicamente proyectos confiables.
ejecutar pip-audit -r "$archivo" --format json --output "$REPORTE/pip-audit.json"
