#!/usr/bin/env bash
# Uso: bash 07-auditar-permisos.sh CARPETA
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/comun.bash"
carpeta="${1:?Indicá una carpeta para inspeccionar}"
[[ -d "$carpeta" ]] || { echo 'Carpeta inexistente.' >&2; exit 64; }
carpeta=$(realpath -e -- "$carpeta")
requerir find
crear_reporte permisos
# No sigue enlaces y no cruza otros sistemas de archivos.
# -0002: escritura para otros. /6000: SUID o SGID en archivos normales.
if ! find "$carpeta" -xdev \( -type f -o -type d \) -perm -0002 -print0 \
    > "$REPORTE/escritura-otros.nul" 2> "$REPORTE/errores.txt"; then
    echo 'Inspección incompleta; consultá errores.txt.' >&2; exit 2
fi
if ! find "$carpeta" -xdev -type f -perm /6000 -print0 \
    > "$REPORTE/suid-sgid.nul" 2>> "$REPORTE/errores.txt"; then
    echo 'Inspección incompleta; consultá errores.txt.' >&2; exit 2
fi
hallazgos=0
for lista in "$REPORTE/escritura-otros.nul" "$REPORTE/suid-sgid.nul"; do
    while IFS= read -r -d '' ruta; do
        printf '%s: %q\n' "$(basename -- "$lista")" "$ruta"
        hallazgos=$((hallazgos + 1))
    done < "$lista"
done > "$REPORTE/permisos.txt"
cat "$REPORTE/permisos.txt"
printf 'Coincidencias a revisar: %s\n' "$hallazgos"
# Son indicadores, no vulnerabilidades confirmadas; no cambia permisos.
if (( hallazgos > 0 )); then exit 1; fi
