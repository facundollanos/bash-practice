#!/usr/bin/env bash
# Uso: REGISTRY=ghcr.io ./01-validar-entorno.sh
set -euo pipefail
: "${REGISTRY:?Definí REGISTRY, por ejemplo ghcr.io}"
for herramienta in docker curl; do
    command -v "$herramienta" >/dev/null || {
        printf 'Falta instalar: %s\n' "$herramienta" >&2
        exit 1
    }
done
docker info >/dev/null
# /v2/ puede responder 401 cuando exige autenticación: eso prueba alcance,
# pero NO demuestra que tengas permiso para publicar imágenes.
http=$(curl -sS --connect-timeout 3 --max-time 10 \
    -o /dev/null -w '%{http_code}' "https://${REGISTRY}/v2/")
case "$http" in
    200|401) printf 'Docker disponible y registro accesible (HTTP %s).\n' "$http" ;;
    *) printf 'Respuesta inesperada del registro: HTTP %s\n' "$http" >&2; exit 1 ;;
esac
