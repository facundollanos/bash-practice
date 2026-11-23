#!/usr/bin/env bash
# Uso: bash 01-sast-python.sh /ruta/al/proyecto/app
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/comun.bash"
objetivo="${1:?Uso: $0 /ruta/al/codigo-python}"
[[ -d "$objetivo" ]] || { printf 'El directorio no existe.\n' >&2; exit 64; }
requerir bandit
crear_reporte sast
# -r: recorrer carpetas. JSON conserva evidencia del hallazgo y su ubicación.
ejecutar bandit -r "$objetivo" -x '.venv,venv,node_modules' \
    -f json -o "$REPORTE/bandit.json"
