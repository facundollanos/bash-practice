#!/usr/bin/env bash
# Uso: bash 11-verificar-manifiesto.sh MANIFIESTO CARPETA_ARTEFACTOS
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/comun.bash"
manifiesto="${1:?Indicá manifiesto SHA256 confiable}"
carpeta="${2:?Indicá carpeta de artefactos}"
[[ -f "$manifiesto" && -r "$manifiesto" && -d "$carpeta" ]] || {
    echo 'Manifiesto o carpeta inválidos.' >&2; exit 64;
}
requerir sha256sum
manifiesto=$(realpath -e -- "$manifiesto")
crear_reporte integridad
# Copia el manifiesto usado para dejar evidencia. Debe provenir de una fuente confiable.
cp -- "$manifiesto" "$REPORTE/manifiesto.sha256"
codigo=0
(
    cd -- "$carpeta"
    sha256sum --check --strict -- "$REPORTE/manifiesto.sha256"
) > "$REPORTE/verificacion.txt" 2> "$REPORTE/errores.txt" || codigo=$?
cat "$REPORTE/verificacion.txt"
cat "$REPORTE/errores.txt" >&2
printf '%s\n' "$codigo" > "$REPORTE/codigo-salida.txt"
exit "$codigo"
