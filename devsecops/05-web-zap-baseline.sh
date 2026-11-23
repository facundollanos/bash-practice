#!/usr/bin/env bash
# Uso Linux: bash 05-web-zap-baseline.sh http://localhost:8000
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/comun.bash"
url="${1:?Uso: $0 URL_HTTP_O_HTTPS}"
case "$url" in
    http://?*|https://?*) ;;
    *) printf 'Indicá una URL http:// o https:// completa.\n' >&2; exit 64 ;;
esac
requerir docker
crear_reporte zap
# El baseline navega por la web y analiza respuestas de forma pasiva.
# Sí genera tráfico: usar en aplicaciones propias o con autorización.
# Usuario actual + HOME temporal evita reportes propiedad de root.
# --network host permite alcanzar localhost en Docker Engine sobre Linux.
ejecutar docker run --rm --network host \
    --user "$(id -u):$(id -g)" -e HOME=/tmp \
    -v "$REPORTE:/zap/wrk:rw" \
    "${ZAP_IMAGE:-ghcr.io/zaproxy/zaproxy:stable}" \
    zap-baseline.py -t "$url" -m 1 -T 5 \
    -r reporte.html -J reporte.json
