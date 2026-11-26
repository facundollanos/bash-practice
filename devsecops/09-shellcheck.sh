#!/usr/bin/env bash
# Uso: bash 09-shellcheck.sh CARPETA
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/comun.bash"
carpeta="${1:?Indicá carpeta con scripts shell}"
[[ -d "$carpeta" ]] || { echo 'Carpeta inexistente.' >&2; exit 64; }
carpeta=$(realpath -e -- "$carpeta")
requerir shellcheck
crear_reporte shellcheck
# Lista NUL: admite rutas con espacios o saltos de línea.
find "$carpeta" -type d \( -name .git -o -name .venv -o -name node_modules \) -prune -o \
    -type f \( -name '*.sh' -o -name '*.bash' \) -print0 > "$REPORTE/archivos.nul"
mapfile -d '' -t archivos < "$REPORTE/archivos.nul"
(( ${#archivos[@]} > 0 )) || { echo 'No se encontraron scripts .sh o .bash.' >&2; exit 64; }
codigo=0
# Analiza texto, NO ejecuta los scripts. No carga fuentes externas automáticamente.
shellcheck --format=json -- "${archivos[@]}" > "$REPORTE/shellcheck.json" || codigo=$?
printf '%s\n' "$codigo" > "$REPORTE/codigo-salida.txt"
printf 'ShellCheck: código %s.\n' "$codigo"
exit "$codigo"
