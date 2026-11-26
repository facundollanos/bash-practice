#!/usr/bin/env bash
# Uso: bash 14-inventariar-archivos.sh CARPETA
set -euo pipefail
carpeta="${1:?Indicá una carpeta}"
[[ -d "$carpeta" ]] || { echo 'Carpeta inexistente.' >&2; exit 64; }
carpeta=$(realpath -e -- "$carpeta")
lista=$(mktemp)
trap 'rm -f -- "$lista"' EXIT
# Primero completar find para no esconder errores de permisos.
find "$carpeta" -xdev -type f -print0 > "$lista"
printf 'BYTES\tMODIFICACION_EPOCH\tPERMISOS\tRUTA_ESCAPADA\n'
while IFS= read -r -d '' archivo; do
    datos=$(stat --printf='%s\t%Y\t%a' -- "$archivo")
    printf '%s\t%q\n' "$datos" "$archivo"
done < "$lista"
