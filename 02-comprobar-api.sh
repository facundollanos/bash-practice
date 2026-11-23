#!/usr/bin/env bash
# Uso: ./02-comprobar-api.sh http://localhost:8000/metrics
set -euo pipefail
url="${1:?Uso: $0 URL}"
for intento in {1..5}; do
    printf 'Intento %s/5: %s\n' "$intento" "$url"
    if http=$(curl -sS --connect-timeout 3 --max-time 5 \
        -o /dev/null -w '%{http_code}' "$url"); then
        if [[ "$http" == 2?? ]]; then
            printf 'OK: HTTP %s\n' "$http"
            exit 0
        fi
        printf 'Respuesta no aceptada: HTTP %s\n' "$http" >&2
    fi
    if (( intento < 5 )); then sleep 2; fi
done
printf 'ERROR: no se recibió una respuesta 2xx.\n' >&2
exit 1
