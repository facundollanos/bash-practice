#!/usr/bin/env bash
# Uso: bash 17-validar-archivos-json.sh DIRECTORIO
set -euo pipefail
directorio_json="${1:?Indicá un directorio con archivos JSON}"
[[ -d "$directorio_json" ]] || { echo 'Directorio inexistente.' >&2; exit 64; }
command -v python3 >/dev/null || { echo 'Falta python3.' >&2; exit 127; }
directorio_json=$(realpath -e -- "$directorio_json")
archivo_lista_temporal=$(mktemp)
trap 'rm -f -- "$archivo_lista_temporal"' EXIT
find "$directorio_json" -type f -name '*.json' -print0 > "$archivo_lista_temporal"
cantidad_archivos=0
cantidad_invalidos=0
while IFS= read -r -d '' ruta_archivo_json; do
    cantidad_archivos=$((cantidad_archivos + 1))
    # Solo parsea datos: no ejecuta ni modifica el archivo.
    if python3 -m json.tool "$ruta_archivo_json" > /dev/null; then
        printf 'VÁLIDO: %q\n' "$ruta_archivo_json"
    else
        printf 'INVÁLIDO: %q\n' "$ruta_archivo_json" >&2
        cantidad_invalidos=$((cantidad_invalidos + 1))
    fi
done < "$archivo_lista_temporal"
(( cantidad_archivos > 0 )) || { echo 'No hay archivos .json.' >&2; exit 64; }
printf 'Analizados: %s; inválidos: %s\n' "$cantidad_archivos" "$cantidad_invalidos"
if (( cantidad_invalidos > 0 )); then exit 1; fi
