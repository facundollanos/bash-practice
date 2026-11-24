#!/usr/bin/env bash
# Uso: bash 08-respaldar-carpeta.sh ORIGEN DESTINO
set -euo pipefail
umask 077
origen="${1:?Indicá la carpeta origen}"
destino="${2:?Indicá la carpeta destino}"
origen=$(realpath -e -- "$origen")
[[ -d "$origen" ]] || { echo 'El origen no es una carpeta.' >&2; exit 64; }
mkdir -p -- "$destino"
destino=$(realpath -e -- "$destino")
# Evita incluir el respaldo dentro de su propio contenido.
if [[ "$origen" == / || "$destino" == "$origen" || "$destino" == "$origen/"* ]]; then
    echo 'El destino debe estar fuera del origen; no se admite respaldar /.' >&2
    exit 64
fi
archivo=$(mktemp "$destino/respaldo-$(date +%Y%m%d-%H%M%S)-XXXXXX.tar.gz")
completo=0
trap 'if (( completo == 0 )); then rm -f -- "$archivo"; fi' EXIT
# El archivo es único; no sobrescribe respaldos anteriores.
tar -czf "$archivo" -C "$(dirname -- "$origen")" -- "$(basename -- "$origen")"
gzip -t -- "$archivo"
completo=1
printf 'Respaldo: %s\n' "$archivo"
